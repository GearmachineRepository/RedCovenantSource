--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
--local Stats = require(Shared.Configurations.Stats)
local StatesModule = require(Shared.Configurations.States)
local States = StatesModule.States

local CombatConfig = require(Shared.Configurations.CombatConfig)

export type PostureController = {
	Controller: any,
	PostureValue: number,
	MaxPosture: number,
	LastHitTime: number,
	IsBroken: boolean,

	GainPosture: (self: PostureController, Amount: number) -> (),
	RecoverPosture: (self: PostureController, Amount: number) -> (),
	PerfectParryRecovery: (self: PostureController) -> (),
	TriggerGuardBreak: (self: PostureController) -> (),
	Update: (self: PostureController, DeltaTime: number) -> (),
}

local PostureController = {}
PostureController.__index = PostureController

function PostureController.new(CharacterController: any): PostureController
	local self = setmetatable({
		Controller = CharacterController,
		PostureValue = 0,
		MaxPosture = CombatConfig.Posture.MAX,
		LastHitTime = 0,
		IsBroken = false,
	}, PostureController)

	return (self :: any) :: PostureController
end

function PostureController:GainPosture(Amount: number, AttackerCharacter: Model?)
	if self.IsBroken then return end

	self.PostureValue += Amount
	self.LastHitTime = tick()

	local Equipment = self.Controller.EquipmentController
	if Equipment then
		local ChestArmor = Equipment:GetEquippedArmor("Chest")
		if ChestArmor and ChestArmor.Metadata.CurrentDurability <= 0 then
			self.PostureValue += Amount * CombatConfig.Posture.BROKEN_ARMOR_BONUS
		end
	end

	self.PostureValue = math.min(self.PostureValue, self.MaxPosture)
	self.Controller.Character:SetAttribute("Posture", self.PostureValue)

	if self.PostureValue >= self.MaxPosture then
		self:TriggerGuardBreak(AttackerCharacter)
	end
end

function PostureController:RecoverPosture(Amount: number)
	self.PostureValue = math.max(0, self.PostureValue - Amount)
	self.Controller.Character:SetAttribute("Posture", self.PostureValue)
end

function PostureController:PerfectParryRecovery()
	self:RecoverPosture(CombatConfig.Posture.PERFECT_PARRY_RECOVERY)
end

function PostureController:TriggerGuardBreak(AttackerCharacter: Model?)
	if self.IsBroken then return end

	self.IsBroken = true
	self.PostureValue = 0

	self.Controller.StateManager:SetState(States.STUNNED, true)
	self.Controller.StateManager:SetState("GuardBroken", true)
	self.Controller.Character:SetAttribute("Posture", 0)

	self.Controller.StateManager:FireEvent("PostureBreak", {
		Character = self.Controller.Character,
	})

	if AttackerCharacter then
		local AttackerController = self.Controller.Get(AttackerCharacter)
		if AttackerController then
			AttackerController.StateManager:SetState(States.RIPOSTE_WINDOW, true)

			if not AttackerController.CombatState then
				AttackerController.CombatState = {}
			end
			AttackerController.CombatState.RiposteTarget = self.Controller.Character

			task.delay(CombatConfig.Riposte.WINDOW, function()
				if AttackerController and AttackerController.Character then
					AttackerController.StateManager:SetState(States.RIPOSTE_WINDOW, false)
					if AttackerController.CombatState then
						AttackerController.CombatState.RiposteTarget = nil
					end
				end
			end)
		end
	end

	task.delay(CombatConfig.Posture.GUARDBREAK_STUN, function()
		self.IsBroken = false
		self.Controller.StateManager:SetState(States.STUNNED, false)
		self.Controller.StateManager:SetState("GuardBroken", false)
	end)
end

function PostureController:Update(DeltaTime: number)
	if self.IsBroken or self.PostureValue <= 0 then return end

	local TimeSinceHit = tick() - self.LastHitTime
	if TimeSinceHit > CombatConfig.Posture.IDLE_DELAY then
		local Resolve = self.Controller.StateManager:GetStat("Resolve") or 10
		local RecoveryBonus = Resolve / 50
		local TotalRecovery = (CombatConfig.Posture.BASE_RECOVERY + RecoveryBonus) * DeltaTime

		self:RecoverPosture(TotalRecovery)
	end
end

function PostureController:Destroy()
	self.PostureValue = 0
	self.IsBroken = false
end

return PostureController