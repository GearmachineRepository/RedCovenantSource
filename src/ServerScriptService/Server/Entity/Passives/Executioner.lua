--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local StatsModule = require(Shared.Stats)
local States = StatsModule.States

local Executioner = {
	Name = "Executioner",
	Description = "Heal 20 HP on kill and gain 10% damage for 5 seconds",
}

function Executioner.Register(Controller)
	local Cleanups = {}
	local DamageBoostCleanup = nil

	table.insert(Cleanups, Controller.StateManager:OnEvent(States.KILLED_ENEMY, function(_)
		Controller.Humanoid.Health = math.min(
			Controller.Humanoid.Health + 20,
			Controller.Humanoid.MaxHealth
		)

		if DamageBoostCleanup then
			DamageBoostCleanup()
		end

		DamageBoostCleanup = Controller:RegisterAttackModifier(200, function(Damage, _)
			return Damage * 1.1
		end)

		task.delay(5, function()
			if DamageBoostCleanup then
				DamageBoostCleanup()
				DamageBoostCleanup = nil
			end
		end)
	end))

	return function()
		for _, Cleanup in Cleanups do
			Cleanup()
		end
		if DamageBoostCleanup then
			DamageBoostCleanup()
		end
	end
end

return Executioner