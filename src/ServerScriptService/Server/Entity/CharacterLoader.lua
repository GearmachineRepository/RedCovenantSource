--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService:WaitForChild("Server")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local EntityModules = Server.Entity

local PassiveRegistry = require(EntityModules.PassiveRegistry)
local CharacterController = require(EntityModules.CharacterController)
local Promise = require(Shared.Packages.Promise)
local Maid = require(Shared.General.Maid)

local Assets = ReplicatedStorage:WaitForChild("Assets")
local EntityAssets = Assets:WaitForChild("Entity")
local CharacterTemplate = EntityAssets:WaitForChild("Character")

local CharacterLoader = {}
local PlayerMaids: {[Player]: Maid.MaidSelf} = {}
local NPCMaids: {[Model]: Maid.MaidSelf} = {}
local ActivePromises: {[any]: typeof(Promise)} = {}

local function GetSpawnLocation(): CFrame
	local SpawnLocations = {}
	for _, Descendant in workspace:GetDescendants() do
		if Descendant:IsA("SpawnLocation") then
			table.insert(SpawnLocations, Descendant)
		end
	end

	if #SpawnLocations > 0 then
		local RandomSpawn = SpawnLocations[math.random(1, #SpawnLocations)]
		return RandomSpawn.CFrame + Vector3.new(0, 3, 0)
	end

	return CFrame.new(0, 10, 0)
end

local function CreateCustomCharacter(Player: Player): Model
	local NewCharacter = CharacterTemplate:Clone()
	NewCharacter.Name = Player.Name

	local Humanoid = NewCharacter:FindFirstChildOfClass("Humanoid")
	if Humanoid then
		Humanoid.DisplayName = Player.DisplayName
	end

	return NewCharacter
end

local function CloneStarterScripts(Character: Model)
	local StarterPlayer = game:GetService("StarterPlayer")
	local StarterCharacterScripts = StarterPlayer:FindFirstChild("StarterCharacterScripts")

	if StarterCharacterScripts then
		for _, Object in StarterCharacterScripts:GetChildren() do
			Object:Clone().Parent = Character
		end
	end
end

function CharacterLoader.SpawnCharacter(Player: Player, Data)
	return Promise.new(function(Resolve, Reject)
		local Character = CreateCustomCharacter(Player)
		local SpawnCFrame = GetSpawnLocation()

		Character:PivotTo(SpawnCFrame)
		Player.Character = Character
		Character.Parent = workspace

		CloneStarterScripts(Character)

		local Success, Humanoid = pcall(function()
			return Character:WaitForChild("Humanoid", 5) :: Humanoid
		end)

		if not Success or not Humanoid then
			Reject("Failed to find Humanoid")
			return
		end

		local Controller = CharacterController.new(Character, true)

		local Passives = PassiveRegistry.GetAll(Data.Passives)
		for _, Passive in Passives do
			Controller.PassiveController:AddPassive(Passive)
		end

		print("Player spawned:", Player.Name)

		Humanoid.Died:Once(function()
			task.wait(3)
			CharacterLoader.LoadPlayer(Player, Data)
		end)

		Resolve(Controller)
	end)
end

local function TrackEntityPromise(Entity: Player|Model, PromiseObj: typeof(Promise), MaidTable: {[any]: Maid.MaidSelf}, ActivePromisesTable: {[any]: typeof(Promise)})
	-- Ensure Maid exists
	local MaidObj = MaidTable[Entity]
	if not MaidObj then
		MaidObj = Maid.new()
		MaidTable[Entity] = MaidObj

		-- Clean up when entity leaves (player leaves or NPC removed)
		MaidObj:GiveTask(Entity.AncestryChanged:Connect(function(_, parent)
			if not parent then
				MaidObj:DoCleaning()
				MaidTable[Entity] = nil
				ActivePromisesTable[Entity] = nil
			end
		end))
	end

	-- Clean up previous tasks/promises
	MaidObj:DoCleaning()

	-- Track the new promise
	MaidObj:GiveTask(PromiseObj)
	ActivePromisesTable[Entity] = PromiseObj
end

function CharacterLoader.LoadPlayer(Player: Player, Data)
	local LoadPromise = CharacterLoader.SpawnCharacter(Player, Data)
		:andThen(function(Controller)
			print("Character fully loaded for:", Player.Name)
			return Controller
		end)
		:catch(function(Error)
			warn("Failed to load character for", Player.Name, ":", Error)
		end)

	TrackEntityPromise(Player, LoadPromise, PlayerMaids, ActivePromises)
	return LoadPromise
end

function CharacterLoader.LoadNPC(NPCCharacter: Model)
	local LoadPromise = Promise.new(function(Resolve, Reject)
		local Success, Result = pcall(function()
			return CharacterController.new(NPCCharacter, false)
		end)

		if Success then
			print("NPC loaded:", NPCCharacter.Name)
			Resolve(Result)
		else
			Reject(Result)
		end
	end)

	TrackEntityPromise(NPCCharacter, LoadPromise, NPCMaids, ActivePromises)
	return LoadPromise
end

return CharacterLoader
