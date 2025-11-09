--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemDatabase = require(Shared.Data.ItemDatabase)
local StatsModule = require(Shared.Configurations.Stats)
local ArmorSetConfig = require(Shared.Configurations.ArmorSetConfig)

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
	if self.EquippedArmor[Slot] then
		self:UnequipArmor(Slot)
	end

	local Template = ItemDatabase.Get(ItemInstance.ItemId)
	if not Template or Template.Type ~= "Armor" then
		warn("Cannot equip non-armor item as armor")
		return
	end

	for StatName, Value in ItemInstance.Metadata do
		if typeof(Value) == "number" then
			local StatConstant = Stats[StatName:upper()]
			if StatConstant then
				self.Controller.StateManager:ModifyStat(StatConstant, Value)

				if StatName == "Health" then
					local Humanoid = self.Controller.Humanoid :: Humanoid
					Humanoid.MaxHealth += Value
					Humanoid.Health += Value
				end
			end
		end
	end

	self.EquippedArmor[Slot] = ItemInstance
	self:CheckSetBonuses()

	print("Equipped armor:", Template.Name, "in slot", Slot)
end

function EquipmentController:UnequipArmor(Slot: string): ItemDatabase.ItemInstance?
	local ItemInstance = self.EquippedArmor[Slot]
	if not ItemInstance then
		return nil
	end

	for StatName, Value in ItemInstance.Metadata do
		if typeof(Value) == "number" then
			local StatConstant = Stats[StatName:upper()]
			if StatConstant then
				self.Controller.StateManager:ModifyStat(StatConstant, -Value)

				if StatName == "Health" then
					local Humanoid = self.Controller.Humanoid :: Humanoid
					Humanoid.MaxHealth -= Value
					Humanoid.Health = math.min(Humanoid.Health, Humanoid.MaxHealth)
				end
			end
		end
	end

	self.EquippedArmor[Slot] = nil
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

    if self.EquippedWeapon and self.EquippedWeapon.ItemId == ItemInstance.ItemId then
        print("Weapon already equipped, skipping:", Template.Name)
        return
    end

    -- Only unequip if there's actually a different weapon equipped
    if self.EquippedWeapon and self.EquippedWeapon.ItemId ~= ItemInstance.ItemId then
        self:UnequipWeapon()
    end

    self.EquippedWeapon = ItemInstance

    if self.Controller.CombatController then
        self.Controller.CombatController:EquipWeapon(Template.Type)
    end

    --print("Equipped weapon:", Template.Name, ItemInstance.ItemId)
end

function EquipmentController:UnequipWeapon(): ItemDatabase.ItemInstance?
	local Weapon = self.EquippedWeapon
	self.EquippedWeapon = nil

	if Weapon then
		if self.Controller.CombatController then
			self.Controller.CombatController:UnequipWeapon()
		end

		--print("Unequipped weapon", Weapon.ItemId)
	end

	return Weapon
end

function EquipmentController:CheckSetBonuses()
	local SetCounts: {[string]: number} = {}

	for _, ItemInstance in self.EquippedArmor do
		if ItemInstance.Metadata.SetName then
			SetCounts[ItemInstance.Metadata.SetName] = (SetCounts[ItemInstance.Metadata.SetName] or 0) + 1
		end
	end

	for SetName, Count in SetCounts do
		local SetData = ArmorSetConfig.GetSet(SetName)
		if not SetData then
			warn("Unknown armor set:", SetName)
			continue
		end

		for _, Bonus in SetData.Bonuses do
			if Count >= Bonus.PiecesRequired then
				print(string.format("%s (%dpc): %s", SetData.Name, Bonus.PiecesRequired, Bonus.Description))
				if Bonus.StatBonuses then
					for StatName, Value in Bonus.StatBonuses do

						if Stats[StatName:upper()] then
							self.Controller.StateManager:ModifyStat(Stats[StatName:upper()], Value)
						end
					end
				end
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