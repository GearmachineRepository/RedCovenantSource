--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StatsModule = require(Shared.Configurations.Stats)
local StatesModule = require(Shared.Configurations.States)
local CombatConfig = require(Shared.Configurations.CombatConfig)
local Maid = require(Shared.General.Maid)
local Promise = require(Shared.Packages.Promise)

local Stats = StatsModule.Stats
local States = StatesModule.States

export type CombatController = {
	Controller: any,
	Maid: Maid.MaidSelf,
	WeaponMaid: Maid.MaidSelf,
	CurrentWeaponModule: any?,
	LastActionTime: number,
	ActionStartTime: number,
	IsInAction: boolean,
	CurrentCombo: number,

	EquipWeapon: (self: CombatController, WeaponType: string) -> (),
	UnequipWeapon: (self: CombatController) -> (),
	CanPerformAction: (self: CombatController) -> boolean,
	StartAction: (self: CombatController, ActionType: string, ComboIndex: number?) -> boolean,
	ValidateHit: (self: CombatController, Target: Model, HitLocation: string) -> (boolean, number?),
	CalculateDamage: (self: CombatController, Target: Model, HitLocation: string) -> number,
	EndAction: (self: CombatController) -> (),
	Update: (self: CombatController, DeltaTime: number) -> (),
	Destroy: (self: CombatController) -> (),
}

local CombatController = {}
CombatController.__index = CombatController

function CombatController.new(CharacterController: any): CombatController
	local self = setmetatable({
		Controller = CharacterController,
		Maid = Maid.new(),
		WeaponMaid = Maid.new(),
		CurrentWeaponModule = nil,
		LastActionTime = 0,
		ActionStartTime = 0,
		IsInAction = false,
		CurrentCombo = 0,
	}, CombatController)

	return (self :: any) :: CombatController
end

function CombatController:EquipWeapon(WeaponType: string)
	self:UnequipWeapon()

	local CombatFolder = Shared:FindFirstChild("Combat")
	if not CombatFolder then
		warn("Combat folder not found in ReplicatedStorage")
		return
	end

	local WeaponsFolder = CombatFolder:FindFirstChild("Weapons")
	if not WeaponsFolder then
		warn("Weapons folder not found in Combat")
		return
	end

	local WeaponModulePath = WeaponsFolder:FindFirstChild(WeaponType)
	if not WeaponModulePath then
		warn("Weapon module not found:", WeaponType, "Available:", WeaponsFolder:GetChildren())
		return
	end

	Promise.try(function()
		local WeaponModule = require(WeaponModulePath)
		return WeaponModule.new(self.Controller)
	end)
		:andThen(function(WeaponModuleInstance)
			self.CurrentWeaponModule = WeaponModuleInstance
			self.CurrentCombo = 0

			if WeaponModuleInstance.Destroy then
				self.WeaponMaid:GiveTask(WeaponModuleInstance)
			end
		end)
		:catch(function(Error)
			warn("Failed to load weapon module", WeaponType, "Error:", Error)
			self.CurrentWeaponModule = nil
		end)
end

function CombatController:UnequipWeapon()
	self.WeaponMaid:DoCleaning()
	self.CurrentWeaponModule = nil
	self.CurrentCombo = 0
end

function CombatController:CanPerformAction(): boolean
	local TimeSinceLastAction = tick() - self.LastActionTime
	if TimeSinceLastAction < CombatConfig.Validation.RATE_LIMIT then
		return false
	end

	if self.Controller.StateManager:GetState(States.STUNNED) then
		return false
	end

	if self.Controller.StateManager:GetState(States.DOWNED) then
		return false
	end

	return true
end

function CombatController:StartAction(ActionType: string, ComboIndex: number?): boolean
	if not self:CanPerformAction() then
		return false
	end

	if not self.CurrentWeaponModule then
		return false
	end

	self.IsInAction = true
	self.ActionStartTime = tick()
	self.LastActionTime = tick()

	if ActionType == "Attack" and ComboIndex then
		self.CurrentCombo = ComboIndex
	end

	self.Controller.StateManager:SetState(States.ATTACKING, true)

	return true
end

function CombatController:ValidateHit(Target: Model, HitLocation: string): (boolean, number?)
	if not self.IsInAction then
		return false, nil
	end

	local ActionDuration = tick() - self.ActionStartTime
	if ActionDuration > CombatConfig.Validation.MAX_ATTACK_DURATION then
		return false, nil
	end

	if ActionDuration < CombatConfig.Validation.MIN_ATTACK_DURATION then
		return false, nil
	end

	local WeaponInstance = self.Controller.EquipmentController:GetEquippedWeapon()
	if not WeaponInstance then
		return false, nil
	end

	local AttackerPos = self.Controller.Character.PrimaryPart.Position
	local TargetPos = Target.PrimaryPart.Position
	local Distance = (AttackerPos - TargetPos).Magnitude

	local MaxRange = WeaponInstance.Metadata.Range + CombatConfig.Validation.RANGE_TOLERANCE
	if Distance > MaxRange then
		return false, nil
	end

	local Damage = self:CalculateDamage(Target, HitLocation)
	return true, Damage
end

function CombatController:CalculateDamage(_: Model, HitLocation: string): number -- Target is unused for now
	local WeaponInstance = self.Controller.EquipmentController:GetEquippedWeapon()
	if not WeaponInstance then
		return 0
	end

	local BaseDamage = WeaponInstance.Metadata.BaseDamage

	local Strength = self.Controller.StateManager:GetStat(Stats.STRENGTH) or 10
	local Agility = self.Controller.StateManager:GetStat(Stats.AGILITY) or 10

	local Scaling = WeaponInstance.Metadata.Scaling or {}
	local StrengthScaling = Scaling.Strength or 0
	local AgilityScaling = Scaling.Agility or 0

	local ScaledDamage = BaseDamage * (1 + (Strength / CombatConfig.Damage.STAT_DIVISOR) * StrengthScaling + (Agility / CombatConfig.Damage.STAT_DIVISOR) * AgilityScaling)

	local Velocity = self.Controller.Character.PrimaryPart.AssemblyLinearVelocity
	local LookVector = self.Controller.Character.PrimaryPart.CFrame.LookVector
	local ForwardVelocity = LookVector:Dot(Velocity)

	if ForwardVelocity > CombatConfig.Momentum.THRESHOLD then
		local MomentumBonus = ForwardVelocity / CombatConfig.Momentum.DAMAGE_DIVISOR
		ScaledDamage = ScaledDamage * (1 + MomentumBonus)
	end

	local LocationMultiplier = CombatConfig.Damage.TORSO_MULTIPLIER
	if HitLocation == "Head" then
		LocationMultiplier = CombatConfig.Damage.HEAD_MULTIPLIER
	elseif HitLocation == "Legs" then
		LocationMultiplier = CombatConfig.Damage.LEGS_MULTIPLIER
	end

	ScaledDamage = ScaledDamage * LocationMultiplier

	if self.Controller.StateManager:GetState("RiposteWindow") then
		ScaledDamage = ScaledDamage * CombatConfig.Riposte.DAMAGE_MULTIPLIER
		self.Controller.StateManager:SetState("RiposteWindow", false)
	end

	return math.floor(ScaledDamage + 0.5)
end

function CombatController:EndAction()
	self.IsInAction = false
	self.Controller.StateManager:SetState(States.ATTACKING, false)
end

function CombatController:Update(_: number) -- DeltaTime is unused for now
	if self.IsInAction then
		local ActionDuration = tick() - self.ActionStartTime

		if ActionDuration > CombatConfig.Validation.MAX_ATTACK_DURATION then
			self:EndAction()
		end
	end
end

function CombatController:Destroy()
	self:UnequipWeapon()
	self.Maid:DoCleaning()
end

return CombatController