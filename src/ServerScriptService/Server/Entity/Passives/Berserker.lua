--!nonstrict
local Berserker = {
	Name = "Berserker",
	Description = "Deal 50% more damage below 30% health",
}

function Berserker.Register(Controller)
	local BerserkerAura = nil

	local function CreateAura()
		if BerserkerAura then return end

		-- local Attachment = Controller.Character:FindFirstChild("WaistCenterAttachment", true) or Controller.Character.PrimaryPart

		-- BerserkerAura = script.Emitter:Clone()
		-- BerserkerAura.Parent = Attachment
		-- BerserkerAura.Enabled = true

		-- BerserkerAura.Parent = Controller.Character.PrimaryPart
	end

	local function RemoveAura()
		if BerserkerAura then
			BerserkerAura:Destroy()
			BerserkerAura = nil
		end
	end

	local HealthConnection = Controller.Humanoid.HealthChanged:Connect(function()
		local HealthPercent = Controller.Humanoid.Health / Controller.Humanoid.MaxHealth

		if HealthPercent < 0.3 and not BerserkerAura then
			CreateAura()
		elseif HealthPercent >= 0.3 and BerserkerAura then
			RemoveAura()
		end
	end)

	local AttackModifierCleanup = Controller:RegisterAttackModifier(100, function(Damage, _)
		local HealthPercent = Controller.Humanoid.Health / Controller.Humanoid.MaxHealth

		if HealthPercent < 0.3 then
			return Damage * 1.5
		end

		return Damage
	end)

	return function()
		RemoveAura()
		HealthConnection:Disconnect()
		AttackModifierCleanup()
	end
end

return Berserker