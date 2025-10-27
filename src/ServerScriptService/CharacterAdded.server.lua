--!strict
local Players = game:GetService("Players")

local Server = script.Parent:WaitForChild("Server")
local CharacterLoader = require(Server.Entity.CharacterLoader)
local PlayerDataTemplate = require(Server.PlayerDataTemplate)
local CharacterController = require(Server.Entity.CharacterController)

Players.PlayerAdded:Connect(function(Player: Player)
	local PlayerData = table.clone(PlayerDataTemplate)

	CharacterLoader.LoadPlayer(Player, PlayerData)
end)

Players.PlayerRemoving:Connect(function(Player)
	if Player.Character then
		local Controller = CharacterController.Get(Player.Character)
		if Controller then
			Controller:Destroy()
		end
	end
end)

CharacterLoader.LoadNPC(workspace:WaitForChild("Rig"))