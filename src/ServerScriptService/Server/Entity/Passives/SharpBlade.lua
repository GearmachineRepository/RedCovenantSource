--!nonstrict
local SharpBlade = {
	Name = "SharpBlade",
	Description = "Increase sword damage by 15%",
}

function SharpBlade.Register(Controller)
	-- Hook into attack damage calculation
	local OriginalCalculateDamage = Controller.CalculateWeaponDamage

	Controller.CalculateWeaponDamage = function(self, Weapon, BaseDamage)
		local Damage = BaseDamage

		-- Apply original calculation if it exists
		if OriginalCalculateDamage then
			Damage = OriginalCalculateDamage(self, Weapon, BaseDamage)
		end

		-- If sword, boost by 15%
		if Weapon:GetAttribute("WeaponType") == "Sword" then
			Damage = Damage * 1.15
		end

		return Damage
	end

	-- Return cleanup
	return function()
		Controller.CalculateWeaponDamage = OriginalCalculateDamage
	end
end

return SharpBlade