--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Combat = Shared:WaitForChild("Combat")
local CombatInputHandler = require(Combat.Client.CombatInputHandler)

local function OnCharacterAdded(Character: Model)
	Character:WaitForChild("Humanoid").Died:Once(function()
		CombatInputHandler:Cleanup()
	end)

	task.wait(0.5)
	CombatInputHandler:Initialize(Character)
end

if Player.Character then
	OnCharacterAdded(Player.Character)
end

Player.CharacterAdded:Connect(OnCharacterAdded)