--!strict
local Stats = {
	-- Core Character Stats
	STRENGTH = "Strength",
	AGILITY = "Agility",
	VITALITY = "Vitality",
	FAITH = "Faith",
	HERESY = "Heresy",
	INTELLIGENCE = "Intelligence",

	-- Dialog Stats (Disco Elysium style)
	PIETY = "Piety",
	PRIDE = "Pride",
	SUPERSTITION = "Superstition",
	DESPAIR = "Despair",
	AMBITION = "Ambition",
	ROT = "Rot",

	-- Combat Stats (derived or equipment-based)
	HEALTH = "Health",
	MAX_HEALTH = "MaxHealth",
	POSTURE = "Posture",
	MAX_POSTURE = "MaxPosture",
	CARRY_WEIGHT = "CarryWeight",
	MAX_CARRY_WEIGHT = "MaxCarryWeight",
	ARMOR = "Armor",
	PHYSICAL_RESISTANCE = "PhysicalResistance",

	-- Movement/Combat States (already defined elsewhere)
	STAMINA = "Stamina",
	MAX_STAMINA = "MaxStamina",
}

local States = {
	-- Combat States (boolean)
	RAGDOLLED = "Ragdolled",
	ATTACKING = "Attacking",
	INVULNERABLE = "Invulnerable",
	STUNNED = "Stunned",
	BLOCKING = "Blocking",
	PARRYING = "Parrying",
	PARRIED = "Parried",
	CLASHING = "Clashing",
	DOWNED = "Downed",
	KILLED = "Killed",

	-- Movement States (boolean)
	SPRINTING = "Sprinting",
	JUMPING = "Jumping",
	FALLING = "Falling",

	-- Special States (boolean)
	IN_CUTSCENE = "InCutscene",

	-- Numeric States
	STAMINA = "Stamina",
	POSTURE = "Posture",
	MAX_STAMINA = "MaxStamina",
	MAX_POSTURE = "MaxPosture",

	-- Events (not states, just names)
	DAMAGE_TAKEN = "DamageTaken",
	DAMAGE_DEALT = "DamageDealt",
	ATTACK_STARTED = "AttackStarted",
	ATTACK_HIT = "AttackHit",
	KILLED_ENEMY = "KilledEnemy",
	PARRY_SUCCESS = "ParrySuccess",
	BLOCK_SUCCESS = "BlockSuccess",
}

-- Default values for states
-- Booleans default to false if not listed here
-- Numbers must have defaults
local Defaults: {[string]: boolean | number} = {
	-- Base character stats
	[Stats.STRENGTH] = 10,
	[Stats.AGILITY] = 10,
	[Stats.VITALITY] = 10,
	[Stats.FAITH] = 0,      -- Starts neutral
	[Stats.HERESY] = 0,     -- Starts neutral
	[Stats.INTELLIGENCE] = 10,

	-- Dialog stats
	[Stats.PIETY] = 0,
	[Stats.PRIDE] = 0,
	[Stats.SUPERSTITION] = 0,
	[Stats.DESPAIR] = 0,
	[Stats.AMBITION] = 0,
	[Stats.ROT] = 0,

	-- Combat stats (calculated from base stats + equipment)
	[Stats.HEALTH] = 100,
	[Stats.MAX_HEALTH] = 100,
	[Stats.POSTURE] = 100,
	[Stats.MAX_POSTURE] = 100,
	[Stats.STAMINA] = 100,
	[Stats.MAX_STAMINA] = 100,
	[Stats.CARRY_WEIGHT] = 0,
	[Stats.MAX_CARRY_WEIGHT] = 100,
	[Stats.ARMOR] = 0,
	[Stats.PHYSICAL_RESISTANCE] = 0,

	-- Any booleans with non-false defaults would go here
	-- (currently none)
}

return {
	Stats = Stats,
	States = States,
	Defaults = Defaults,
}