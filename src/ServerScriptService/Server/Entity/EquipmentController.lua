--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemDatabase = require(Shared.Data.ItemDatabase)
local StatsModule = require(Shared.Stats)
local Stats = StatsModule.Stats

export type EquipmentController = {
	Controller: any,
	EquippedArmor: {[string]: ItemDatabase.ItemInstance},
	EquippedWeapon: ItemDatabase.ItemInstance?,

	EquipArmor: (self: EquipmentController, ItemInstance: ItemDatabase.ItemInstance, Slot: string) -> (),
	UnequipArmor: (self: EquipmentController, Slot: string) -> ItemDatabase.ItemInstance?,
	EquipWeapon: (self: EquipmentController, ItemInstance: ItemDatabase.ItemInstance) -> (),
	UnequipWeapon: (self: EquipmentController) -> ItemDatabase.ItemInstance?,
	CheckSetBonuses: (self: EquipmentController) -> (),
	GetEquippedArmor: (self: EquipmentController, Slot: string) -> ItemDatabase.ItemInstance?,
	GetEquippedWeapon: (self: EquipmentController) -> ItemDatabase.ItemInstance?,
}

local EquipmentController = {}
EquipmentController.__index = EquipmentController

function EquipmentController.new(CharacterController: any): EquipmentController
	local self = setmetatable({
		Controller = CharacterController :: typeof(CharacterController),
		EquippedArmor = {},
		EquippedWeapon = nil,
	}, EquipmentController)

	return (self :: any) :: EquipmentController
end

function EquipmentController:EquipArmor(ItemInstance: ItemDatabase.ItemInstance, Slot: string)
	-- Unequip current armor in slot if exists
	if self.EquippedArmor[Slot] then
		self:UnequipArmor(Slot)
	end

	local Template = ItemDatabase.Get(ItemInstance.ItemId)
	if not Template or Template.Type ~= "Armor" then
		warn("Cannot equip non-armor item as armor")
		return
	end

	-- Apply armor value
	if ItemInstance.Metadata.Armor then
		self.Controller.StateManager:ModifyStat(Stats.ARMOR, ItemInstance.Metadata.Armor)
	end

	-- Apply stat bonuses from metadata
	if ItemInstance.Metadata.Health then
		self.Controller.StateManager:ModifyStat(Stats.MAX_HEALTH, ItemInstance.Metadata.Health)
		local Humanoid = self.Controller.Humanoid :: Humanoid
		Humanoid.MaxHealth += ItemInstance.Metadata.Health
		Humanoid.Health += ItemInstance.Metadata.Health
	end

	if ItemInstance.Metadata.Posture then
		self.Controller.StateManager:ModifyStat(Stats.MAX_POSTURE, ItemInstance.Metadata.Posture)
	end

	if ItemInstance.Metadata.PhysicalResistance then
		self.Controller.StateManager:ModifyStat(Stats.PHYSICAL_RESISTANCE, ItemInstance.Metadata.PhysicalResistance)
	end

	if ItemInstance.Metadata.Strength then
		self.Controller.StateManager:ModifyStat(Stats.STRENGTH, ItemInstance.Metadata.Strength)
	end

	if ItemInstance.Metadata.Agility then
		self.Controller.StateManager:ModifyStat(Stats.AGILITY, ItemInstance.Metadata.Agility)
	end

	if ItemInstance.Metadata.Vitality then
		self.Controller.StateManager:ModifyStat(Stats.VITALITY, ItemInstance.Metadata.Vitality)
	end

	-- Store equipped armor
	self.EquippedArmor[Slot] = ItemInstance

	-- Check set bonuses
	self:CheckSetBonuses()

	print("Equipped armor:", Template.Name, "in slot", Slot)
end

function EquipmentController:UnequipArmor(Slot: string): ItemDatabase.ItemInstance?
	local ItemInstance = self.EquippedArmor[Slot]
	if not ItemInstance then
		return nil
	end

	-- Remove armor value
	if ItemInstance.Metadata.Armor then
		self.Controller.StateManager:ModifyStat(Stats.ARMOR, -ItemInstance.Metadata.Armor)
	end

	-- Remove stat bonuses
	if ItemInstance.Metadata.Health then
		self.Controller.StateManager:ModifyStat(Stats.MAX_HEALTH, -ItemInstance.Metadata.Health)
		local Humanoid = self.Controller.Humanoid :: Humanoid
		Humanoid.MaxHealth -= ItemInstance.Metadata.Health
		Humanoid.Health = math.min(Humanoid.Health, Humanoid.MaxHealth)
	end

	if ItemInstance.Metadata.Posture then
		self.Controller.StateManager:ModifyStat(Stats.MAX_POSTURE, -ItemInstance.Metadata.Posture)
	end

	if ItemInstance.Metadata.PhysicalResistance then
		self.Controller.StateManager:ModifyStat(Stats.PHYSICAL_RESISTANCE, -ItemInstance.Metadata.PhysicalResistance)
	end

	if ItemInstance.Metadata.Strength then
		self.Controller.StateManager:ModifyStat(Stats.STRENGTH, -ItemInstance.Metadata.Strength)
	end

	if ItemInstance.Metadata.Agility then
		self.Controller.StateManager:ModifyStat(Stats.AGILITY, -ItemInstance.Metadata.Agility)
	end

	if ItemInstance.Metadata.Vitality then
		self.Controller.StateManager:ModifyStat(Stats.VITALITY, -ItemInstance.Metadata.Vitality)
	end

	-- Remove from equipped
	self.EquippedArmor[Slot] = nil

	-- Recheck set bonuses
	self:CheckSetBonuses()

	print("Unequipped armor from slot", Slot)

	return ItemInstance
end

function EquipmentController:EquipWeapon(ItemInstance: ItemDatabase.ItemInstance)
	local Template = ItemDatabase.Get(ItemInstance.ItemId)
	if not Template or (Template.Type ~= "Sword" and Template.Type ~= "Axe" and Template.Type ~= "Spear" and Template.Type ~= "Mace") then
		warn("Cannot equip non-weapon item as weapon")
		return
	end

	self.EquippedWeapon = ItemInstance

	print("Equipped weapon:", Template.Name)
end

function EquipmentController:UnequipWeapon(): ItemDatabase.ItemInstance?
	local Weapon = self.EquippedWeapon
	self.EquippedWeapon = nil

	if Weapon then
		print("Unequipped weapon")
	end

	return Weapon
end

function EquipmentController:CheckSetBonuses()
	local SetCounts: {[string]: number} = {}

	-- Count equipped items per set
	for _, ItemInstance in self.EquippedArmor do -- Slot, ItemInstance
		if ItemInstance.Metadata.SetName then
			SetCounts[ItemInstance.Metadata.SetName] = (SetCounts[ItemInstance.Metadata.SetName] or 0) + 1
		end
	end

	-- Apply set bonuses (example implementation)
	for SetName, Count in SetCounts do
		if SetName == "ItalianPlate" then
			if Count >= 2 then
				print("Italian Plate 2pc Bonus: +10 Agility (TODO: Implement)")
			end
			if Count >= 3 then
				print("Italian Plate 3pc Bonus: +15% Movement Speed (TODO: Implement)")
			end
		elseif SetName == "GermanGothic" then
			if Count >= 2 then
				print("German Gothic 2pc Bonus: +20 Health (TODO: Implement)")
			end
		end
	end
end

function EquipmentController:GetEquippedArmor(Slot: string): ItemDatabase.ItemInstance?
	return self.EquippedArmor[Slot]
end

function EquipmentController:GetEquippedWeapon(): ItemDatabase.ItemInstance?
	return self.EquippedWeapon
end

return EquipmentController