--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StatsModule = require(Shared.Stats)
local States = StatsModule.States

export type PostureController = {
	Controller: any,
	PostureValue: number,
	MaxPosture: number,
	IsBroken: boolean,
	LastHitTime: number,
	RecoveryRate: number,

	GainPosture: (self: PostureController, Amount: number, Source: Model?) -> (),
	RecoverPosture: (self: PostureController, Amount: number) -> (),
	TriggerGuardBreak: (self: PostureController) -> (),
	Update: (self: PostureController, DeltaTime: number) -> (),
}

local PostureController = {}
PostureController.__index = PostureController

function PostureController.new(CharacterController: any): PostureController
	local self = setmetatable({
		Controller = CharacterController,
		PostureValue = 0,
		MaxPosture = 100,
		IsBroken = false,
		LastHitTime = 0,
		RecoveryRate = 0.8,
	}, PostureController)

	return (self :: any) :: PostureController
end

function PostureController:GainPosture(Amount: number, _: Model?) -- Source parameter reserved for future use (model that caused posture gain)
	if self.IsBroken then return end

	self.PostureValue += Amount
	self.LastHitTime = tick()

	-- Armor durability affects posture (from spec)
	local Equipment = self.Controller.EquipmentController
	if Equipment:IsArmorBroken() then
		self.PostureValue += Amount * 0.3
	end

	-- Clamp to max
	self.PostureValue = math.min(self.PostureValue, self.MaxPosture)

	-- Update attribute for client
	self.Controller.Character:SetAttribute("Posture", self.PostureValue)

	-- Check for guard break
	if self.PostureValue >= self.MaxPosture then
		self:TriggerGuardBreak()
	end
end

function PostureController:RecoverPosture(Amount: number)
	self.PostureValue -= Amount
	self.PostureValue = math.max(0, self.PostureValue)

	self.Controller.Character:SetAttribute("Posture", self.PostureValue)
end

function PostureController:TriggerGuardBreak()
	if self.IsBroken then return end

	self.IsBroken = true
	self.PostureValue = 0

	-- From spec: 0.7s stun on guard break
	self.Controller.StateManager:SetState(States.STUNNED, true)
	self.Controller.StateManager:SetState("GuardBroken", true)

	self.Controller.Character:SetAttribute("Posture", 0)

	-- Fire event for relics/passives
	self.Controller.StateManager:FireEvent("PostureBreak", {
		Character = self.Controller.Character,
	})

	-- Recovery after stun
	task.delay(0.7, function()
		self.IsBroken = false
		self.Controller.StateManager:SetState(States.STUNNED, false)
		self.Controller.StateManager:SetState("GuardBroken", false)
	end)
end

function PostureController:Update(DeltaTime: number)
	if self.IsBroken then return end
	if self.PostureValue <= 0 then return end

	-- From spec: Idle recovery after 2s delay
	local TimeSinceHit = tick() - self.LastHitTime
	if TimeSinceHit > 2.0 then
		-- From spec: Recovery rate = 0.8 + Resolve/50
		local Resolve = self.Controller.StateManager:GetStat("Resolve") or 0
		local RecoveryBonus = Resolve / 50
		local TotalRecovery = (self.RecoveryRate + RecoveryBonus) * DeltaTime

		self:RecoverPosture(TotalRecovery)
	end
end

return PostureController