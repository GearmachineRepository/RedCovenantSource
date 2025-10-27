--!strict
local PassiveRegistry = {}

local LoadedPassives: {[string]: any} = {}

function PassiveRegistry.Get(PassiveName: string)
	if LoadedPassives[PassiveName] then
		return LoadedPassives[PassiveName]
	end

	-- Try to load it
	local PassivesFolder = script.Parent.Passives
	local PassiveModule = PassivesFolder:FindFirstChild(PassiveName)

	if PassiveModule then
		local Success, Passive = pcall(require, PassiveModule)
		if Success then
			LoadedPassives[PassiveName] = Passive
			return Passive
		else
			warn("Failed to load passive:", PassiveName, Passive)
		end
	else
		warn("Passive module not found:", PassiveName)
	end

	return nil
end

function PassiveRegistry.GetAll(PassiveNames: {string}): {any}
	local Passives = {}

	for _, PassiveName in PassiveNames do
		local Passive = PassiveRegistry.Get(PassiveName)
		if Passive then
			table.insert(Passives, Passive)
		end
	end

	return Passives
end

return PassiveRegistry