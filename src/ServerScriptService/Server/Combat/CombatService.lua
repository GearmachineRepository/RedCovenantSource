--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("Server")

local CharacterController = require(Server.Entity.CharacterController)
local ItemDatabase = require(Shared.Data.ItemDatabase)
local StatsModule = require(Shared.Stats)
local Stats = StatsModule.Stats
local States = StatsModule.States
local CombatConfig = require(script.Parent.CombatConfig)
local Packets = require(Shared.Networking.Packets)

local CombatService = {}

type HitData = {
	Target: Model,
	HitLocation: string,
	HitPosition: Vector3,
	Timestamp: number,
}

function CombatService:ValidateHitRequest(Player: Player, HitData: HitData): (boolean, string?)
	local AttackerController = CharacterController.Get(Player.Character)
	if not AttackerController then
		return false, "No attacker controller"
	end

	local TargetController = CharacterController.Get(HitData.Target)
	if not TargetController then
		return false, "Invalid target"
	end

	-- Rate limiting
	local LastAttackTime = AttackerController.CombatState and AttackerController.CombatState.LastAttackTime or 0
	local TimeSinceLastAttack = tick() - LastAttackTime

	if TimeSinceLastAttack < CombatConfig.Cooldowns.ATTACK then
		return false, "Attack too soon"
	end

	-- Latency compensation (±0.1s tolerance from spec)
	local ServerTime = tick()
	local Latency = ServerTime - HitData.Timestamp

	if math.abs(Latency) > 0.1 then
		return false, "Timestamp out of sync"
	end

	-- Get weapon for range validation
	local WeaponInstance = AttackerController.EquipmentController:GetEquippedWeapon()
	if not WeaponInstance then
		return false, "No weapon equipped"
	end

	local Template = ItemDatabase.Get(WeaponInstance.ItemId)

	-- Distance validation
	local AttackerPos = Player.Character.PrimaryPart.Position
	local TargetPos = HitData.Target.PrimaryPart.Position
	local Distance = (AttackerPos - TargetPos).Magnitude

	local MaxRange = Template.Range or 5.0
	local RangeTolerance = 2.0

	if Distance > (MaxRange + RangeTolerance) then
		return false, "Target out of range"
	end

	-- State validation
	if AttackerController.StateManager:GetState(States.STUNNED) then
		return false, "Attacker stunned"
	end

	if TargetController.StateManager:GetState(States.INVULNERABLE) then
		return false, "Target invulnerable"
	end

	return true
end

function CombatService:CalculateWeaponDamage(AttackerController, WeaponInstance): number
	if not WeaponInstance then return 10 end

	local BaseDamage = WeaponInstance.Metadata.BaseDamage
	local Scaling = WeaponInstance.Metadata.Scaling

	local Strength = AttackerController.StateManager:GetStat(Stats.STRENGTH) or 10
	local Agility = AttackerController.StateManager:GetStat(Stats.AGILITY) or 10

	local StrengthScaling = (Scaling and Scaling.Strength) or 0
	local AgilityScaling = (Scaling and Scaling.Agility) or 0

	-- From spec: Base × (1 + (STR or DEX)/100) × WeaponScaling
	local ScaledDamage = BaseDamage * (1 + (Strength / 100) * StrengthScaling + (Agility / 100) * AgilityScaling)

	return ScaledDamage
end

function CombatService:CalculateMomentumBonus(Character: Model): number
	local PrimaryPart = Character.PrimaryPart
	if not PrimaryPart then return 0 end

	local Velocity = PrimaryPart.AssemblyLinearVelocity
	local LookVector = PrimaryPart.CFrame.LookVector
	local ForwardVelocity = LookVector:Dot(Velocity)

	-- From spec: ForwardVelocity > 5 threshold
	if ForwardVelocity > CombatConfig.Momentum.THRESHOLD then
		-- From spec: ForwardVelocity/20 × DamageMultiplier
		return ForwardVelocity / 20
	end

	return 0
end

function CombatService:CalculatePostureDamage(WeaponInstance): number
	if not WeaponInstance then return 15 end

	local Weight = WeaponInstance.Metadata.Weight or 10

	-- From spec: 15 + (Attacker.WeaponWeight × 2)
	return 15 + (Weight * 2)
end

function CombatService:ProcessHit(Player: Player, HitData: HitData)
	local AttackerController = CharacterController.Get(Player.Character)
	if not AttackerController then return end

	-- Validate hit
	local IsValid, ErrorMsg = self:ValidateHitRequest(Player, HitData)
	if not IsValid then
		warn("Invalid hit:", ErrorMsg)
		return
	end

	-- Update last attack time
	if not AttackerController.CombatState then
		AttackerController.CombatState = {}
	end
	AttackerController.CombatState.LastAttackTime = tick()

	-- Get weapon
	local WeaponInstance = AttackerController.EquipmentController:GetEquippedWeapon()

	-- Calculate damage components
	local WeaponDamage = self:CalculateWeaponDamage(AttackerController, WeaponInstance)
	local MomentumBonus = self:CalculateMomentumBonus(Player.Character)
	local FinalDamage = WeaponDamage * (1 + MomentumBonus)

	-- Calculate posture damage
	local PostureDamage = self:CalculatePostureDamage(WeaponInstance)

	-- Check if target is blocking
	local TargetController = CharacterController.Get(HitData.Target)
	local WasBlocked = TargetController.StateManager:GetState(States.BLOCKING)

	-- Apply health damage through existing system (handles AttackModifiers and DamageModifiers)
	AttackerController:DealDamage(HitData.Target, FinalDamage)

	-- Apply posture damage (Deepwoken style - always applies, more if blocked)
	if TargetController.PostureController then
		if WasBlocked then
			-- Blocking takes more posture damage
			TargetController.PostureController:GainPosture(PostureDamage * 1.5, Player.Character)
		else
			TargetController.PostureController:GainPosture(PostureDamage * 0.5, Player.Character)
		end
	end

	-- Send confirmation to attacker for visual feedback
	Packets.CombatHitConfirmed:FireClient(Player, HitData.Target, FinalDamage, WasBlocked, HitData.HitLocation)
end

function CombatService:Initialize()
	-- Handle attack requests
	Packets.RequestAttack.OnServerEvent:Connect(function(Player: Player)
		local Controller = CharacterController.Get(Player.Character)
		if not Controller then return end

		-- Server-side validation
		if Controller.CooldownController:IsOnCooldown("Attack") then
			-- Cancel client animation
			Packets.CancelAttack:FireClient(Player)
			return
		end

		if Controller.StateManager:GetState(States.STUNNED) then
			Packets.CancelAttack:FireClient(Player)
			return
		end

		-- Authorize attack
		Controller.CooldownController:StartCooldown("Attack", CombatConfig.Cooldowns.ATTACK)
	end)

	-- Handle hit detection from client
	Packets.CombatHit.OnServerEvent:Connect(function(Player: Player, Target: Model, HitLocation: string, HitPosition: Vector3, Timestamp: number)
		local HitData: HitData = {
			Target = Target,
			HitLocation = HitLocation,
			HitPosition = HitPosition,
			Timestamp = Timestamp,
		}

		self:ProcessHit(Player, HitData)
	end)
end

return CombatService