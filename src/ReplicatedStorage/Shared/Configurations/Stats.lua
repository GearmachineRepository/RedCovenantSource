--!strict

local Stats = {
	STRENGTH = "Strength",
	AGILITY = "Agility",
	VITALITY = "Vitality",
	FAITH = "Faith",
	HERESY = "Heresy",
	INTELLIGENCE = "Intelligence",
	RESOLVE = "Resolve",

	PIETY = "Piety",
	PRIDE = "Pride",
	SUPERSTITION = "Superstition",
	DESPAIR = "Despair",
	AMBITION = "Ambition",
	ROT = "Rot",

	HEALTH = "Health",
	MAX_HEALTH = "MaxHealth",
	POSTURE = "Posture",
	MAX_POSTURE = "MaxPosture",
	STAMINA = "Stamina",
	MAX_STAMINA = "MaxStamina",
	CARRY_WEIGHT = "CarryWeight",
	MAX_CARRY_WEIGHT = "MaxCarryWeight",
	ARMOR = "Armor",
	PHYSICAL_RESISTANCE = "PhysicalResistance",
}

local Defaults = {
	[Stats.STRENGTH] = 10,
	[Stats.AGILITY] = 10,
	[Stats.VITALITY] = 10,
	[Stats.FAITH] = 0,
	[Stats.HERESY] = 0,
	[Stats.INTELLIGENCE] = 10,
	[Stats.RESOLVE] = 10,

	[Stats.PIETY] = 0,
	[Stats.PRIDE] = 0,
	[Stats.SUPERSTITION] = 0,
	[Stats.DESPAIR] = 0,
	[Stats.AMBITION] = 0,
	[Stats.ROT] = 0,

	[Stats.HEALTH] = 100,
	[Stats.MAX_HEALTH] = 100,
	[Stats.POSTURE] = 0,
	[Stats.MAX_POSTURE] = 100,
	[Stats.STAMINA] = 100,
	[Stats.MAX_STAMINA] = 100,
	[Stats.CARRY_WEIGHT] = 0,
	[Stats.MAX_CARRY_WEIGHT] = 100,
	[Stats.ARMOR] = 0,
	[Stats.PHYSICAL_RESISTANCE] = 0,
}

return {
	Stats = Stats,
	Defaults = Defaults,
}