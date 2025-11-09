--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared.General.Maid)

export type AxeWeapon = {
	Controller: any,
	Maid: Maid.MaidSelf,

	PerformLightAttack: (self: AxeWeapon, ComboIndex: number) -> (),
	PerformHeavyAttack: (self: AxeWeapon) -> (),
	PerformBlock: (self: AxeWeapon) -> (),
	PerformParry: (self: AxeWeapon) -> (),
	Destroy: (self: AxeWeapon) -> (),
}

local AxeWeapon = {}
AxeWeapon.__index = AxeWeapon

AxeWeapon.MaxComboLength = 2
AxeWeapon.ComboResetTime = 2.5
AxeWeapon.AttackDuration = 0.8
AxeWeapon.HeavyAttackDuration = 1.2


AxeWeapon.Animations = {
	LightAttack1 = "rbxassetid://0",
	LightAttack2 = "rbxassetid://0",
	HeavyAttack = "rbxassetid://0",
	Block = "rbxassetid://0",
	Parry = "rbxassetid://0",
}

AxeWeapon.HitboxWindows = {
	LightAttack1 = {Start = 0.3, End = 0.6},
	LightAttack2 = {Start = 0.35, End = 0.65},
	HeavyAttack = {Start = 0.5, End = 0.9},
}

function AxeWeapon.new(CharacterController: any): AxeWeapon
	local self = setmetatable({
		Controller = CharacterController,
		Maid = Maid.new(),
	}, AxeWeapon)

	return (self :: any) :: AxeWeapon
end

function AxeWeapon:PerformLightAttack(ComboIndex: number)
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

function AxeWeapon:PerformHeavyAttack()
	task.delay(self.HeavyAttackDuration, function()
		if self.Controller.CombatController then
			self.Controller.CombatController:EndAction()
		end
	end)
end

function AxeWeapon:PerformBlock()
	self.Controller.StateManager:SetState("Blocking", true)
end

function AxeWeapon:PerformParry()
	self.Controller.StateManager:SetState("Parrying", true)

	task.delay(0.2, function()
		self.Controller.StateManager:SetState("Parrying", false)
	end)
end

function AxeWeapon:Destroy()
	self.Maid:DoCleaning()
end

return AxeWeapon