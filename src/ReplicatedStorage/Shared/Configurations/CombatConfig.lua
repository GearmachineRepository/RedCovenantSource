--!strict

local CombatConfig = {
	Validation = {
		MAX_ATTACK_DURATION = 4.0,
		MIN_ATTACK_DURATION = 0.1,
		ENDLAG_WINDOW = 0.25,
		RATE_LIMIT = 0.15,
		LATENCY_TOLERANCE = 0.15,
		RANGE_TOLERANCE = 2.5,
	},

	Damage = {
		STAT_DIVISOR = 100,
		HEAD_MULTIPLIER = 1.5,
		TORSO_MULTIPLIER = 1.0,
		LEGS_MULTIPLIER = 0.8,
	},

	Momentum = {
		THRESHOLD = 5,
		DAMAGE_DIVISOR = 20,
	},

	Posture = {
		MAX = 100,
		BASE_DAMAGE = 15,
		WEIGHT_MULTIPLIER = 2,
		BASE_RECOVERY = 0.8,
		IDLE_DELAY = 1.5,
		GUARDBREAK_STUN = 0.7,
		BLOCKED_MULTIPLIER = 1.0,
		HIT_MULTIPLIER = 0.3,
		BROKEN_ARMOR_BONUS = 0.5,
		PERFECT_PARRY_RECOVERY = 20,
	},

	Parry = {
		WINDOW = 0.20,
		SUCCESS_STUN = 0.35,
		FAIL_RECOIL = 0.25,
		FAIL_POSTURE_PERCENT = 0.18,
		CONE_ANGLE = 140,
	},

	Block = {
		CONE_ANGLE = 140,
		POSTURE_MULTIPLIER = 1.0,
		DAMAGE_REDUCTION = 0.5,
	},

	Riposte = {
		WINDOW = 0.5,
		DAMAGE_MULTIPLIER = 1.5,
	},

	Armor = {
		DURABILITY_LOSS_LIGHT = 1,
		DURABILITY_LOSS_HEAVY = 2,
		Resistances = {
			Leather = {Slash = 0.1, Pierce = 0.05, Blunt = 0.15},
			Mail = {Slash = 0.3, Pierce = 0.2, Blunt = 0.1},
			Plate = {Slash = 0.4, Pierce = 0.35, Blunt = 0.2},
		},
	},
}

return CombatConfig