--!strict
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService:WaitForChild("Server")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local CharacterController = require(Server.Entity.CharacterController)
local ItemDatabase = require(Shared.Data.ItemDatabase)

local TestWeapons = {
	{ItemId = 1, Name = "Rusty Longsword"},
	{ItemId = 2, Name = "Knight's Longsword"},
	{ItemId = 3, Name = "War Axe"},
}

local function CreateWeaponTool(ItemId: number): Tool
	local WeaponInstance = ItemDatabase.CreateInstance(ItemId)
	if not WeaponInstance then
		warn("Failed to create weapon instance")
		return nil :: any
	end

	local Template = ItemDatabase.Get(ItemId)

	local Tool = Instance.new("Tool")
	Tool.Name = Template.Name
	Tool.RequiresHandle = true
	Tool.CanBeDropped = false

	local Handle = Instance.new("Part")
	Handle.Name = "Handle"
	Handle.Size = Vector3.new(0.5, 4, 0.5)
	Handle.CanCollide = false
	Handle.BrickColor = BrickColor.new("Medium stone grey")
	Handle.Parent = Tool

	local Attachment = Instance.new("Attachment")
	Attachment.Name = "DmgPoint"
	Attachment.Parent = Handle

	Tool:SetAttribute("ItemId", ItemId)
	Tool:SetAttribute("WeaponType", Template.Type)

	local CurrentCharacter: Model?
	local CurrentPlayer: Player?

    Tool.Equipped:Connect(function()
        CurrentCharacter = Tool.Parent :: Model
        if not CurrentCharacter or not CurrentCharacter:IsA("Model") then return end

        CurrentPlayer = Players:GetPlayerFromCharacter(CurrentCharacter)
        if not CurrentPlayer then return end

        local Controller = CharacterController.Get(CurrentCharacter)
        if not Controller or not Controller.EquipmentController then return end

        local ExistingMotor = Handle:FindFirstChild("WeaponMotor")
        if ExistingMotor then
            ExistingMotor:Destroy()
        end

        local Motor6D = Instance.new("Motor6D")
        Motor6D.Name = "WeaponMotor"
        Motor6D.Part0 = CurrentCharacter:FindFirstChild("Right Arm") or CurrentCharacter:FindFirstChild("RightHand")
        Motor6D.Part1 = Handle
        Motor6D.C0 = CFrame.new(0, -1, 0)
        Motor6D.Parent = Handle

        Controller.EquipmentController:EquipWeapon(WeaponInstance)
    end)

    Tool.Unequipped:Connect(function()
        if not CurrentCharacter or not CurrentPlayer then return end

        local Controller = CharacterController.Get(CurrentCharacter)
        if Controller and Controller.EquipmentController then
            local CurrentlyEquipped = Controller.EquipmentController:GetEquippedWeapon()
            if CurrentlyEquipped and CurrentlyEquipped.ItemId == WeaponInstance.ItemId then
                Controller.EquipmentController:UnequipWeapon()
            end
        end

        -- Clean up the motor when unequipping
        local Motor = Handle:FindFirstChild("WeaponMotor")
        if Motor then
            Motor:Destroy()
        end

        CurrentCharacter = nil
        CurrentPlayer = nil
    end)

	return Tool
end

Players.PlayerAdded:Connect(function(Player: Player)
    task.wait(1)

    local Backpack = Player:FindFirstChild("Backpack")
    if not Backpack then return end

    for _, WeaponData in TestWeapons do
        local Tool = CreateWeaponTool(WeaponData.ItemId)
        if Tool then
            Tool.Parent = Backpack
        end
    end

    print("Gave test weapons to", Player.Name)
end)