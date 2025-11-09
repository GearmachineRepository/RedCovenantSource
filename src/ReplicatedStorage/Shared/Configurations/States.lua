--!strict

local States = {
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
	SPRINTING = "Sprinting",
	JUMPING = "Jumping",
	FALLING = "Falling",
	IN_CUTSCENE = "InCutscene",
	GUARD_BROKEN = "GuardBroken",
	RIPOSTE_WINDOW = "RiposteWindow",
	DODGING = "Dodging",
	IFRAME = "Iframe",
}

local Events = {
	DAMAGE_TAKEN = "DamageTaken",
	DAMAGE_DEALT = "DamageDealt",
	ATTACK_STARTED = "AttackStarted",
	ATTACK_HIT = "AttackHit",
	KILLED_ENEMY = "KilledEnemy",
	PARRY_SUCCESS = "ParrySuccess",
	PARRY_FAILED = "ParryFailed",
	BLOCK_SUCCESS = "BlockSuccess",
	POSTURE_BREAK = "PostureBreak",
	RIPOSTE_STARTED = "RiposteStarted",
	DODGE_STARTED = "DodgeStarted",
}

return {
	States = States,
	Events = Events,
}