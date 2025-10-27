--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Maid = require(Shared.General.Maid)

export type Passive = {
	Name: string,
	Description: string?,
	Register: (Controller: any) -> (() -> ())?,  -- Returns cleanup function
}

local PassiveController = {}
PassiveController.__index = PassiveController

export type PassiveController = typeof(setmetatable({} :: {
	Controller: any,
	ActivePassives: {[string]: {Passive: any, Cleanup: (() -> ())?}},
	Maid: any,
}, PassiveController))

function PassiveController.new(Controller): PassiveController
	local self = setmetatable({
		Controller = Controller,
		ActivePassives = {},
		Maid = Maid.new(),
	}, PassiveController)

	return self
end

function PassiveController:AddPassive(Passive: Passive)
	if self.ActivePassives[Passive.Name] then
		warn("Passive already active:", Passive.Name)
		return
	end

	-- Register passive and store cleanup function
	local Cleanup = Passive.Register(self.Controller)

	self.ActivePassives[Passive.Name] = {
		Passive = Passive,
		Cleanup = Cleanup,
	}
end

function PassiveController:RemovePassive(PassiveName: string)
	local PassiveData = self.ActivePassives[PassiveName]

	if not PassiveData then
		warn("Passive not active:", PassiveName)
		return
	end

	-- Call cleanup if it exists
	if PassiveData.Cleanup then
		PassiveData.Cleanup()
	end

	self.ActivePassives[PassiveName] = nil
end

function PassiveController:HasPassive(PassiveName: string): boolean
	return self.ActivePassives[PassiveName] ~= nil
end

function PassiveController:GetActivePassives(): {string}
	local Names = {}
	for PassiveName, _ in self.ActivePassives do
		table.insert(Names, PassiveName)
	end
	return Names
end

function PassiveController:Destroy()
	-- Clean up all passives
	for PassiveName, _ in self.ActivePassives do
		self:RemovePassive(PassiveName)
	end

	self.Maid:DoCleaning()
end

return PassiveController