--!strict
export type StatRoll = {
	min: number,
	max: number,
}

export type WeaponTemplate = {
	Name: string,
	Type: string,
	Culture: string?,
	Rarity: string,
	Description: string?,
	AttackSpeed: number,
	Range: number,
	Weight: number,
	BaseDamage: StatRoll,
	Scaling: {
		Strength: number?,
		Agility: number?,
		Faith: number?,
		Intelligence: number?,
	}?,
	Requirements: {
		Strength: number?,
		Agility: number?,
		Faith: number?,
	}?,
	DamageType: string,
	Model: string?,
	Icon: string?,
}

export type ArmorTemplate = {
	Name: string,
	Type: string,
	Slot: string,
	Culture: string?,
	SetName: string?,
	Rarity: string,
	Description: string?,
	Weight: number,
	Armor: StatRoll,
	StatBonuses: {
		Health: StatRoll?,
		Posture: StatRoll?,
		Stamina: StatRoll?,
		PhysicalResistance: StatRoll?,
		Strength: StatRoll?,
		Agility: StatRoll?,
		Vitality: StatRoll?,
	}?,
	Requirements: {
		Strength: number?,
	}?,
	Model: string?,
	Icon: string?,
}

export type ConsumableTemplate = {
	Name: string,
	Type: string,
	Stackable: boolean,
	MaxStack: number?,
	Rarity: string,
	Description: string?,
	DefaultMetadata: {
		HealAmount: number?,
		StaminaRestore: number?,
		BuffDuration: number?,
		BuffType: string?,
	},
	Icon: string?,
}

export type ItemTemplate = WeaponTemplate | ArmorTemplate | ConsumableTemplate

export type ItemInstance = {
	ItemId: number,
	Metadata: {[string]: any},
}

-- Separate the data from the module
local Items: {[number]: ItemTemplate} = {
	-- WEAPONS
	[1] = {
		Name = "Rusty Longsword",
		Type = "Sword",
		Culture = "German",
		Rarity = "Common",
		Description = "A worn longsword, barely serviceable.",
		AttackSpeed = 1.0,
		Range = 3.5,
		Weight = 15,
		BaseDamage = {min = 18, max = 22},
		Scaling = {
			Strength = 0.5,
		},
		Requirements = {
			Strength = 10,
		},
		DamageType = "Slash",
	},

	[2] = {
		Name = "Knight's Longsword",
		Type = "Sword",
		Culture = "German",
		Rarity = "Uncommon",
		Description = "A well-maintained longsword used by knights.",
		AttackSpeed = 1.0,
		Range = 3.5,
		Weight = 15,
		BaseDamage = {min = 25, max = 30},
		Scaling = {
			Strength = 0.8,
		},
		Requirements = {
			Strength = 15,
		},
		DamageType = "Slash",
	},

	[3] = {
		Name = "War Axe",
		Type = "Axe",
		Culture = "English",
		Rarity = "Common",
		Description = "A heavy axe meant for cleaving.",
		AttackSpeed = 0.8,
		Range = 3.0,
		Weight = 20,
		BaseDamage = {min = 22, max = 28},
		Scaling = {
			Strength = 1.0,
		},
		Requirements = {
			Strength = 14,
		},
		DamageType = "Slash",
	},

	[4] = {
		Name = "Spear",
		Type = "Spear",
		Rarity = "Common",
		Description = "A simple spear with good reach.",
		AttackSpeed = 1.1,
		Range = 5.0,
		Weight = 10,
		BaseDamage = {min = 15, max = 20},
		Scaling = {
			Strength = 0.4,
			Agility = 0.3,
		},
		Requirements = {
			Strength = 8,
			Agility = 8,
		},
		DamageType = "Pierce",
	},

	[5] = {
		Name = "Mace",
		Type = "Mace",
		Rarity = "Common",
		Description = "Effective against armor.",
		AttackSpeed = 0.9,
		Range = 3.0,
		Weight = 18,
		BaseDamage = {min = 20, max = 24},
		Scaling = {
			Strength = 0.7,
		},
		Requirements = {
			Strength = 12,
		},
		DamageType = "Blunt",
	},

	-- ARMOR
	[100] = {
		Name = "Gambeson",
		Type = "Armor",
		Slot = "Chest",
		Culture = "Common",
		Rarity = "Common",
		Description = "Padded cloth armor worn by commoners.",
		Weight = 8,
		Armor = {min = 5, max = 10},
		StatBonuses = {
			Health = {min = 5, max = 10},
		},
	},

	[101] = {
		Name = "Italian Plate Chestplate",
		Type = "Armor",
		Slot = "Chest",
		Culture = "Italian",
		SetName = "ItalianPlate",
		Rarity = "Rare",
		Description = "Finely crafted Italian plate armor. Balanced and mobile.",
		Weight = 25,
		Armor = {min = 40, max = 55},
		StatBonuses = {
			Health = {min = 10, max = 20},
			Posture = {min = 5, max = 10},
			PhysicalResistance = {min = 5, max = 15},
		},
		Requirements = {
			Strength = 15,
		},
	},

	[102] = {
		Name = "German Gothic Helmet",
		Type = "Armor",
		Slot = "Head",
		Culture = "German",
		SetName = "GermanGothic",
		Rarity = "Rare",
		Description = "Heavy German helmet with excellent protection.",
		Weight = 15,
		Armor = {min = 25, max = 35},
		StatBonuses = {
			Health = {min = 8, max = 15},
			PhysicalResistance = {min = 8, max = 12},
		},
		Requirements = {
			Strength = 12,
		},
	},

	[103] = {
		Name = "English Brigandine Gauntlets",
		Type = "Armor",
		Slot = "Arms",
		Culture = "English",
		SetName = "EnglishBrigandine",
		Rarity = "Uncommon",
		Description = "Versatile brigandine gauntlets.",
		Weight = 6,
		Armor = {min = 12, max = 18},
		StatBonuses = {
			Health = {min = 3, max = 8},
			Agility = {min = 1, max = 3},
		},
	},

	-- CONSUMABLES
	[200] = {
		Name = "Health Potion",
		Type = "Consumable",
		Stackable = true,
		MaxStack = 10,
		Rarity = "Common",
		Description = "Restores health.",
		DefaultMetadata = {
			HealAmount = 50,
		},
	},

	[201] = {
		Name = "Greater Health Potion",
		Type = "Consumable",
		Stackable = true,
		MaxStack = 5,
		Rarity = "Uncommon",
		Description = "Restores a large amount of health.",
		DefaultMetadata = {
			HealAmount = 100,
		},
	},
}

-- Module functions
local ItemDatabase = {}

function ItemDatabase.Get(ItemId: number): ItemTemplate?
	return Items[ItemId]
end

function ItemDatabase.CreateInstance(ItemId: number, MetadataOverrides: {[string]: any}?): ItemInstance?
	local Template = Items[ItemId]
	if not Template then
		return nil
	end

	local Metadata: {[string]: any} = {}

	if Template.Type == "Consumable" then
		Metadata = table.clone((Template :: ConsumableTemplate).DefaultMetadata)

	elseif Template.Type == "Armor" then
		local ArmorTemplate = Template :: ArmorTemplate

		Metadata.Armor = math.random(ArmorTemplate.Armor.min, ArmorTemplate.Armor.max)
		Metadata.Weight = ArmorTemplate.Weight

		if ArmorTemplate.StatBonuses then
			for StatName, Roll in pairs(ArmorTemplate.StatBonuses) do
				Metadata[StatName] = math.random(Roll.min, Roll.max)
			end
		end

		if ArmorTemplate.SetName then
			Metadata.SetName = ArmorTemplate.SetName
		end

	else
		local WeaponTemplate = Template :: WeaponTemplate

		Metadata.BaseDamage = math.random(WeaponTemplate.BaseDamage.min, WeaponTemplate.BaseDamage.max)
		Metadata.AttackSpeed = WeaponTemplate.AttackSpeed
		Metadata.Range = WeaponTemplate.Range
		Metadata.Weight = WeaponTemplate.Weight
		Metadata.DamageType = WeaponTemplate.DamageType

		if WeaponTemplate.Scaling then
			Metadata.Scaling = table.clone(WeaponTemplate.Scaling)
		end
	end

	if MetadataOverrides then
		for Key, Value in MetadataOverrides do
			Metadata[Key] = Value
		end
	end

	return {
		ItemId = ItemId,
		Metadata = Metadata,
	}
end

return ItemDatabase