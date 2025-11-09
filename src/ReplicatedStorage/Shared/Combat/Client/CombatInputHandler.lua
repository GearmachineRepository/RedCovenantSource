--!strict
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Shared = ReplicatedStorage:WaitForChild("Shared")
local ClientCombatController = require(script.Parent.ClientCombatController)
local Maid = require(Shared.General.Maid)

local CombatInputHandler = {}
CombatInputHandler.Controller = nil :: ClientCombatController.ClientCombatController?
CombatInputHandler.Maid = Maid.new()

function CombatInputHandler:Initialize(Character: Model)
	self:Cleanup()

	self.Controller = ClientCombatController.new(Character)
	self.Maid = Maid.new()

	self.Maid:GiveTask(UserInputService.InputBegan:Connect(function(Input: InputObject, GameProcessed: boolean)
		if GameProcessed then return end
		if not self.Controller then return end

		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.Controller:RequestAction("LightAttack", 1)

		elseif Input.KeyCode == Enum.KeyCode.R then
			self.Controller:RequestAction("HeavyAttack")

		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.Controller:RequestAction("Block")

		elseif Input.KeyCode == Enum.KeyCode.F then
			self.Controller:RequestAction("Parry")
		end
	end))

	self.Maid:GiveTask(UserInputService.InputEnded:Connect(function(Input: InputObject, GameProcessed: boolean)
		if GameProcessed then return end
		if not self.Controller then return end

		if Input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.Controller:RequestAction("StopBlock")
		end
	end))
end

function CombatInputHandler:Cleanup()
	if self.Controller then
		self.Controller:Destroy()
		self.Controller = nil
	end

	self.Maid:DoCleaning()
end

return CombatInputHandler