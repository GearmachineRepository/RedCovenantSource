--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared.General.Maid)

export type SwordWeapon = {
	Controller: any,
	Maid: Maid.MaidSelf,

	PerformLightAttack: (self: SwordWeapon, ComboIndex: number) -> (),
	PerformHeavyAttack: (self: SwordWeapon) -> (),
	PerformBlock: (self: SwordWeapon) -> (),
	PerformParry: (self: SwordWeapon) -> (),
	Destroy: (self: SwordWeapon) -> (),
}

local SwordWeapon = {}
SwordWeapon.__index = SwordWeapon

SwordWeapon.MaxComboLength = 3
SwordWeapon.ComboResetTime = 2.0
SwordWeapon.AttackDuration = 0.6
SwordWeapon.HeavyAttackDuration = 1.0

SwordWeapon.Animations = {
	LightAttack1 = "rbxassetid://18537375492",
	LightAttack2 = "rbxassetid://18537372803",
	LightAttack3 = "rbxassetid://18537370321",
	HeavyAttack = "rbxassetid://0",
	Block = "rbxassetid://18897108350",
	Parry = "rbxassetid://18897108350",
}

SwordWeapon.HitboxWindows = {
	LightAttack1 = {Start = 0.2, End = 0.4},
	LightAttack2 = {Start = 0.15, End = 0.35},
	LightAttack3 = {Start = 0.25, End = 0.45},
	HeavyAttack = {Start = 0.4, End = 0.7},
}

function SwordWeapon.new(CharacterController: any): SwordWeapon
	local self = setmetatable({
		Controller = CharacterController,
		Maid = Maid.new(),
	}, SwordWeapon)

	return (self :: any) :: SwordWeapon
end

function SwordWeapon:PerformLightAttack(ComboIndex: number)
	local AnimationName = "LightAttack" .. ComboIndex
	local Window = self.HitboxWindows[AnimationName]

	if not Window then
		warn("No hitbox window for:", AnimationName)
		return
	end

	task.delay(self.AttackDuration, function()
		if self.Controller.CombatController then
			self.Controller.CombatController:EndAction()
		end
	end)
end

function SwordWeapon:PerformHeavyAttack()
	--local Window = self.HitboxWindows.HeavyAttack

	task.delay(self.HeavyAttackDuration, function()
		if self.Controller.CombatController then
			self.Controller.CombatController:EndAction()
		end
	end)
end

function SwordWeapon:PerformBlock()
	self.Controller.StateManager:SetState("Blocking", true)
end

function SwordWeapon:PerformParry()
	self.Controller.StateManager:SetState("Parrying", true)

	task.delay(0.2, function()
		self.Controller.StateManager:SetState("Parrying", false)
	end)
end

function SwordWeapon:Destroy()
	self.Maid:DoCleaning()
end

return SwordWeapon