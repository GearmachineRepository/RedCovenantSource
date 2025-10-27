--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Maid = require(Shared.General.Maid)

export type StateValue = boolean | number | string
export type EventData = {[string]: any}
export type StateCallback = (NewValue: StateValue, OldValue: StateValue?) -> ()
export type EventCallback = (Data: EventData) -> ()

local StateManager = {}
StateManager.__index = StateManager

export type StateManager = typeof(setmetatable({} :: {
	Character: Model,
	States: {[string]: StateValue},
	StateListeners: {[string]: {StateCallback}},
	EventListeners: {[string]: {EventCallback}},
	Maid: any,
}, StateManager))

function StateManager.new(Character: Model): StateManager
	local self = setmetatable({
		Character = Character :: Model,
		States = {} :: {[string]: StateValue},
		StateListeners = {} :: {[string]: {StateCallback}},
		EventListeners = {} :: {[string]: {EventCallback}},
		Maid = Maid.new(),
	}, StateManager)

	return self
end

function StateManager:SetState(StateName: string, Value: StateValue)
	local OldValue = self.States[StateName]

	if OldValue == Value then
		return
	end

	self.States[StateName] = Value
	self.Character:SetAttribute(StateName, Value)

	if self.StateListeners[StateName] then
		for _, Callback in self.StateListeners[StateName] do
			task.spawn(Callback, Value, OldValue)
		end
	end
end

function StateManager:GetState(StateName: string): StateValue?
	return self.States[StateName]
end

function StateManager:ModifyState(StateName: string, Amount: number)
	local Current = self:GetState(StateName)
	if typeof(Current) == "number" then
		self:SetState(StateName, Current + Amount)
	end
end

function StateManager:OnStateChanged(StateName: string, Callback: StateCallback)
	if not self.StateListeners[StateName] then
		self.StateListeners[StateName] = {}
	end

	table.insert(self.StateListeners[StateName], Callback)

	return function()
		local Index = table.find(self.StateListeners[StateName], Callback)
		if Index then
			table.remove(self.StateListeners[StateName], Index)
		end
	end
end

function StateManager:SetStat(StatName: string, Value: number)
	return self:SetState(StatName, Value)
end

function StateManager:GetStat(StatName: string): number?
	local Value = self:GetState(StatName)
	if typeof(Value) == "number" then
		return Value
	end
	return nil
end

function StateManager:ModifyStat(StatName: string, Amount: number)
	return self:ModifyState(StatName, Amount)
end

function StateManager:OnStatChanged(StatName: string, Callback: StateCallback)
	return self:OnStateChanged(StatName, Callback)
end

function StateManager:FireEvent(EventName: string, Data: EventData?)
	if not self.EventListeners[EventName] then
		return
	end

	local EventData = Data or {}

	for _, Callback in self.EventListeners[EventName] do
		task.spawn(Callback, EventData)
	end
end

function StateManager:OnEvent(EventName: string, Callback: EventCallback)
	if not self.EventListeners[EventName] then
		self.EventListeners[EventName] = {}
	end

	table.insert(self.EventListeners[EventName], Callback)

	return function()
		local Index = table.find(self.EventListeners[EventName], Callback)
		if Index then
			table.remove(self.EventListeners[EventName], Index)
		end
	end
end

function StateManager:Destroy()
	self.Maid:DoCleaning()
	table.clear(self.States)
	table.clear(self.StateListeners)
	table.clear(self.EventListeners)
end

return StateManager