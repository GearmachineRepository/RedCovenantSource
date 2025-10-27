--!strict
local CommandUtil = require(script.Parent.Parent.CommandUtil)

return {
	Description = "Show debug information about your character",
	Usage = "!debug",
	Execute = function(Player: Player)
		local Controller = CommandUtil.GetController(Player)
		if not Controller then
			return
		end

		local DebugInfo = Controller:GetDebugInfo()

		print("=== DEBUG INFO:", Player.Name, "===")
		print("Character:", DebugInfo.CharacterName)
		print("Is Player:", DebugInfo.IsPlayer)
		print("Health:", DebugInfo.Health)

		print("\nActive States:")
		if #DebugInfo.ActiveStates > 0 then
			for _, StateName in DebugInfo.ActiveStates do
				print("  -", StateName)
			end
		else
			print("  (none)")
		end

		print("\nActive Passives:")
		if #DebugInfo.ActivePassives > 0 then
			for _, PassiveName in DebugInfo.ActivePassives do
				print("  -", PassiveName)
			end
		else
			print("  (none)")
		end

		print("\nModifier Counts:")
		for ModifierType, Count in DebugInfo.ModifierCounts do
			print(string.format("  %s: %d", ModifierType, Count))
		end

		print("==================")
	end
}