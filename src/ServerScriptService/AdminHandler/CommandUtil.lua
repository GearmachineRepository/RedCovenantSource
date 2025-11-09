--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService:WaitForChild("Server")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local CharacterController = require(Server.Entity.CharacterController)
local PassiveRegistry = require(Server.Entity.PassiveRegistry)
local StatsModule = require(Shared.Configurations.Stats)
local StatesModule = require(Shared.Configurations.States)

local CommandUtil = {}

CommandUtil.States = StatesModule.States
CommandUtil.Stats = StatsModule.Stats

function CommandUtil.GetController(Player: Player)
	local Character = Player.Character or workspace:FindFirstChild(Player.Name)

	if not Character then
		warn("No character found for", Player.Name)
		return nil
	end

	local Controller = CharacterController.Get(Character)
	if not Controller then
		warn("Controller not found. Try waiting a moment after spawning.")
		return nil
	end

	return Controller
end

function CommandUtil.GetCharacter(Player: Player): Model?
	return Player.Character or workspace:FindFirstChild(Player.Name)
end

function CommandUtil.GetPassive(PassiveName: string)
	return PassiveRegistry.Get(PassiveName)
end

return CommandUtil