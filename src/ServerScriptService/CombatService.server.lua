--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService:WaitForChild("Server")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local CharacterController = require(Server.Entity.CharacterController)
local Packets = require(Shared.Networking.Packets)
local CombatConfig = require(Shared.Configurations.CombatConfig)
local StatesModule = require(Shared.Configurations.States)
local HitDetection = require(Server.Combat.HitDetection)

local States = StatesModule.States

local function ValidateParry(Attacker: Model, Defender: Model): boolean
	local AttackerPos = Attacker.PrimaryPart.Position
	local DefenderPos = Defender.PrimaryPart.Position
	local DefenderLook = Defender.PrimaryPart.CFrame.LookVector

	local DirectionToAttacker = (AttackerPos - DefenderPos).Unit
	local DotProduct = DefenderLook:Dot(DirectionToAttacker)
	local Angle = math.deg(math.acos(math.clamp(DotProduct, -1, 1)))

	return Angle <= (CombatConfig.Parry.CONE_ANGLE / 2)
end

local function ProcessParrySuccess(AttackerController: any, DefenderController: any)
	AttackerController.StateManager:SetState(States.STUNNED, true)
	AttackerController.StateManager:SetState("Parried", true)

	if AttackerController.PostureController then
		local PostureDamage = AttackerController.PostureController.MaxPosture * CombatConfig.Parry.FAIL_POSTURE_PERCENT
		AttackerController.PostureController:GainPosture(PostureDamage)
	end

	if DefenderController.PostureController then
		DefenderController.PostureController:PerfectParryRecovery()
	end

	DefenderController.StateManager:SetState("RiposteWindow", true)

	task.delay(CombatConfig.Parry.SUCCESS_STUN, function()
		AttackerController.StateManager:SetState(States.STUNNED, false)
		AttackerController.StateManager:SetState("Parried", false)
	end)

	task.delay(CombatConfig.Riposte.WINDOW, function()
		DefenderController.StateManager:SetState("RiposteWindow", false)
	end)
end

local function ProcessHit(Attacker: Model, Target: Model, HitLocation: string)
	local AttackerController = CharacterController.Get(Attacker)
	local TargetController = CharacterController.Get(Target)

	if not AttackerController or not TargetController then
		return
	end

	local MaxRange = CombatConfig.Range.MAX_HIT_DISTANCE
	local IsWithinRange = HitDetection.ValidateDistance(Attacker, Target, MaxRange)
	local IsInFront = HitDetection.IsInFrontCone(Attacker, Target, 140)

	if not (IsWithinRange and IsInFront) then
		local Player = game.Players:GetPlayerFromCharacter(Attacker)
		if Player then
			Packets.RollbackAction:FireClient(Player)
		end
		return
	end

	if not AttackerController.CombatController then
		return
	end

	local IsTargetParrying = TargetController.StateManager:GetState("Parrying")
	if IsTargetParrying and ValidateParry(Attacker, Target) then
		ProcessParrySuccess(AttackerController, TargetController)
		return
	end

	local IsValid, Damage = AttackerController.CombatController:ValidateHit(Target, HitLocation)
	if not IsValid or not Damage then
		local Player = game.Players:GetPlayerFromCharacter(Attacker)
		if Player then
			Packets.RollbackAction:FireClient(Player)
		end
		return
	end

	local WasBlocked = TargetController.StateManager:GetState("Blocking")

	AttackerController:DealDamage(Target, Damage)

	if TargetController.PostureController then
		local WeaponInstance = AttackerController.EquipmentController:GetEquippedWeapon()
		if WeaponInstance then
			local Weight = WeaponInstance.Metadata.Weight or 10
			local PostureDamage = CombatConfig.Posture.BASE_DAMAGE + (Weight * CombatConfig.Posture.WEIGHT_MULTIPLIER)

			if WasBlocked then
				PostureDamage = PostureDamage * CombatConfig.Posture.BLOCKED_MULTIPLIER
			else
				PostureDamage = PostureDamage * CombatConfig.Posture.HIT_MULTIPLIER
			end

			TargetController.PostureController:GainPosture(PostureDamage)
		end
	end

	local Player = game.Players:GetPlayerFromCharacter(Attacker)
	if Player then
		Packets.ValidateHit:FireClient(Player, Attacker, Target, Damage, HitLocation)
	end
end

Packets.RequestCombatAction.OnServerEvent:Connect(function(Player: Player, ActionType: string, ComboIndex: number)
	local Character = Player.Character
	if not Character then return end

	local Controller = CharacterController.Get(Character)
	if not Controller or not Controller.CombatController then return end

	local Success = Controller.CombatController:StartAction(ActionType, ComboIndex)
	if not Success then
		Packets.RollbackAction:FireClient(Player)
		return
	end

	if Controller.CombatController.CurrentWeaponModule then
		local WeaponModule = Controller.CombatController.CurrentWeaponModule

		if ActionType == "LightAttack" and WeaponModule.PerformLightAttack then
			WeaponModule:PerformLightAttack(ComboIndex)
		elseif ActionType == "HeavyAttack" and WeaponModule.PerformHeavyAttack then
			WeaponModule:PerformHeavyAttack()
		elseif ActionType == "Block" and WeaponModule.PerformBlock then
			WeaponModule:PerformBlock()
		elseif ActionType == "Parry" and WeaponModule.PerformParry then
			WeaponModule:PerformParry()
		end
	end
end)

Packets.CombatHitRegistered.OnServerEvent:Connect(function(Player: Player, Target: Model, HitLocation: string, _: Vector3)
	local Character = Player.Character
	if not Character then return end

	ProcessHit(Character, Target, HitLocation)
end)