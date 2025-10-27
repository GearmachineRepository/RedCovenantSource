--!strict
local Packet = require(script.Parent.Parent
	:WaitForChild("Packages")
	:WaitForChild("Packet"))

return {
	-- Combat
	RequestAttack = Packet("RequestAttack", Packet.Instance, Packet.String),
	DamageDealt = Packet("DamageDealt", Packet.Instance, Packet.NumberU8, Packet.Boolean8),

	-- Equipment
	EquipItem = Packet("EquipItem", Packet.NumberU16, Packet.String),
	UnequipItem = Packet("UnequipItem", Packet.String),

	-- Passives
	TogglePassive = Packet("TogglePassive", Packet.String, Packet.Boolean8),

	-- State Replication
	StateChanged = Packet("StateChanged", Packet.Instance, Packet.String, Packet.Any),
	EventFired = Packet("EventFired", Packet.Instance, Packet.String, Packet.Any),
}