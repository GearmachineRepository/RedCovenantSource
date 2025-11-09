--!strict
local Packet = require(script.Parent.Parent
	:WaitForChild("Packages")
	:WaitForChild("Packet"))

return {
	-- Combat
	RequestAttack = Packet("RequestAttack"),
	CancelAttack = Packet("CancelAttack"),
	CombatHit = Packet("CombatHit", Packet.Instance, Packet.String, Packet.Vector3, Packet.NumberF64),
	CombatHitConfirmed = Packet("CombatHitConfirmed", Packet.Instance, Packet.NumberF32, Packet.Boolean8, Packet.String),
	RequestCombatAction = Packet("RequestCombatAction", Packet.String, Packet.NumberU8),
	CombatHitRegistered = Packet("CombatHitRegistered", Packet.Instance, Packet.String, Packet.Vector3F32),
	ValidateHit = Packet("ValidateHit", Packet.Instance, Packet.Instance, Packet.NumberU16, Packet.String),
	RollbackAction = Packet("RollbackAction"),

	-- Equipment
	EquipItem = Packet("EquipItem", Packet.NumberU16, Packet.String),
	UnequipItem = Packet("UnequipItem", Packet.String),

	-- Passives
	TogglePassive = Packet("TogglePassive", Packet.String, Packet.Boolean8),

	-- State Replication
	StateChanged = Packet("StateChanged", Packet.Instance, Packet.String, Packet.Any),
	EventFired = Packet("EventFired", Packet.Instance, Packet.String, Packet.Any),
}