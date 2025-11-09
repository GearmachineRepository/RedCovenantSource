--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("Server")

local StateManager = require(Server.Entity.StateManager)
local PassiveController = require(Server.Entity.PassiveController)
local EquipmentController = require(Server.Entity.EquipmentController)
local CombatController = require(Server.Combat.CombatController)
local PostureController = require(Server.Combat.PostureController)
local StatsModule = require(Shared.Configurations.Stats)
local StatesModule = require(Shared.Configurations.States)
local States = StatesModule.States
local Defaults = StatsModule.Defaults
local StateHandlers = require(Server.Entity.StateHandlers)
local Maid = require(Shared.General.Maid)

local CharacterController = {}
CharacterController.__index = CharacterController

export type DamageModifier = (Damage: number, Data: {[string]: any}) -> number
export type HealingModifier = (HealAmount: number, Data: {[string]: any}) -> number
export type StaminaCostModifier = (Cost: number, Data: {[string]: any}) -> number
export type SpeedModifier = (Speed: number, Data: {[string]: any}) -> number

export type ControllerType = typeof(setmetatable({} :: {
	Character: Model,
	Humanoid: Humanoid,
	IsPlayer: boolean,
	Maid: Maid.MaidSelf,
	StateManager: StateManager.StateManager,
	PassiveController: PassiveController.PassiveController,
	EquipmentController: EquipmentController.EquipmentController,
	CombatController: any,
	PostureController: PostureController.PostureController?,
	StateMachine: any,
	DamageModifiers: {{Priority: number, Modifier: DamageModifier}},
	AttackModifiers: {{Priority: number, Modifier: DamageModifier}},
	HealingModifiers: {{Priority: number, Modifier: HealingModifier}},
	StaminaCostModifiers: {{Priority: number, Modifier: StaminaCostModifier}},
	SpeedModifiers: {{Priority: number, Modifier: SpeedModifier}},
}, CharacterController))

local Controllers: {[Model]: ControllerType} = {}

function CharacterController.new(Character: Model, IsPlayer: boolean): ControllerType
	local self = setmetatable({
		Character = Character,
		Humanoid = Character:WaitForChild("Humanoid") :: Humanoid,
		IsPlayer = IsPlayer,
		Maid = Maid.new(),
		StateManager = nil :: StateManager.StateManager?,
		PassiveController = nil :: PassiveController.PassiveController?,
		EquipmentController = nil :: EquipmentController.EquipmentController?,
		CombatController = nil :: any,
		PostureController = nil :: PostureController.PostureController?,
		StateMachine = nil :: any,
		DamageModifiers = {},
		AttackModifiers = {},
		HealingModifiers = {},
		StaminaCostModifiers = {},
		SpeedModifiers = {},
	}, CharacterController) :: ControllerType

	self.StateManager = StateManager.new(Character)
	self.PassiveController = PassiveController.new(self)
	self.EquipmentController = EquipmentController.new(self)
	self.CombatController = CombatController.new(self)
	self.PostureController = PostureController.new(self)

	Character:SetAttribute("HasController", true)
	Controllers[Character] = self

	self:InitializeStates()
	StateHandlers.Setup(self)
	self:SetupHumanoidStateTracking()

	self.Maid:GiveTask(self.Humanoid.Died:Connect(function()
		self:Destroy()
	end))

	return self
end

function CharacterController:InitializeStates()
	for StateName, DefaultValue in Defaults do
		self.StateManager:SetState(StateName, DefaultValue)
	end

	for _, StateName in pairs(States) do
		if Defaults[StateName] == nil then
			self.StateManager:SetState(StateName, false)
		end
	end
end

function CharacterController:SetupHumanoidStateTracking()
	local Humanoid = self.Humanoid

	self.Maid:GiveTask(RunService.Heartbeat:Connect(function(DeltaTime)
		if self.CombatController then
			self.CombatController:Update(DeltaTime)
		end

		if self.PostureController then
			self.PostureController:Update(DeltaTime)
		end

		local IsMoving = self.Character.PrimaryPart.Velocity.Magnitude > 1
		local IsOnGround = Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
		local IsSprinting = IsMoving and IsOnGround and Humanoid.WalkSpeed > 16

		self.StateManager:SetState(States.SPRINTING, IsSprinting)
	end))

	local IsInAir = false

	self.Maid:GiveTask(Humanoid.StateChanged:Connect(function(_, NewState)
		if NewState == Enum.HumanoidStateType.Jumping or NewState == Enum.HumanoidStateType.Freefall then
			if not IsInAir then
				IsInAir = true
				self.StateManager:SetState(States.JUMPING, true)
			end
		elseif NewState == Enum.HumanoidStateType.Landed or NewState == Enum.HumanoidStateType.Running then
			if IsInAir then
				IsInAir = false
				self.StateManager:SetState(States.JUMPING, false)
				self.StateManager:SetState(States.FALLING, false)
			end
		end

		if NewState == Enum.HumanoidStateType.Freefall then
			self.StateManager:SetState(States.FALLING, true)
		end
	end))

	self.Maid:GiveTask(Humanoid.FreeFalling:Connect(function(IsFreeFalling)
		if not IsFreeFalling and IsInAir then
			IsInAir = false
			self.StateManager:SetState(States.JUMPING, false)
			self.StateManager:SetState(States.FALLING, false)
		end
	end))
end

function CharacterController:RegisterDamageModifier(Priority: number, Modifier: DamageModifier)
	table.insert(self.DamageModifiers, {
		Priority = Priority,
		Modifier = Modifier,
	})

	table.sort(self.DamageModifiers, function(a, b)
		return a.Priority > b.Priority
	end)

	return function()
		for i, Entry in self.DamageModifiers do
			if Entry.Modifier == Modifier then
				table.remove(self.DamageModifiers, i)
				break
			end
		end
	end
end

function CharacterController:RegisterAttackModifier(Priority: number, Modifier: DamageModifier)
	table.insert(self.AttackModifiers, {
		Priority = Priority,
		Modifier = Modifier,
	})

	table.sort(self.AttackModifiers, function(a, b)
		return a.Priority > b.Priority
	end)

	return function()
		for i, Entry in self.AttackModifiers do
			if Entry.Modifier == Modifier then
				table.remove(self.AttackModifiers, i)
				break
			end
		end
	end
end

function CharacterController:RegisterHealingModifier(Priority: number, Modifier: HealingModifier)
	table.insert(self.HealingModifiers, {
		Priority = Priority,
		Modifier = Modifier,
	})

	table.sort(self.HealingModifiers, function(a, b)
		return a.Priority > b.Priority
	end)

	return function()
		for i, Entry in self.HealingModifiers do
			if Entry.Modifier == Modifier then
				table.remove(self.HealingModifiers, i)
				break
			end
		end
	end
end

function CharacterController:RegisterStaminaCostModifier(Priority: number, Modifier: StaminaCostModifier)
	table.insert(self.StaminaCostModifiers, {
		Priority = Priority,
		Modifier = Modifier,
	})

	table.sort(self.StaminaCostModifiers, function(a, b)
		return a.Priority > b.Priority
	end)

	return function()
		for i, Entry in self.StaminaCostModifiers do
			if Entry.Modifier == Modifier then
				table.remove(self.StaminaCostModifiers, i)
				break
			end
		end
	end
end

function CharacterController:RegisterSpeedModifier(Priority: number, Modifier: SpeedModifier)
	table.insert(self.SpeedModifiers, {
		Priority = Priority,
		Modifier = Modifier,
	})

	table.sort(self.SpeedModifiers, function(a, b)
		return a.Priority > b.Priority
	end)

	return function()
		for i, Entry in self.SpeedModifiers do
			if Entry.Modifier == Modifier then
				table.remove(self.SpeedModifiers, i)
				break
			end
		end
	end
end

function CharacterController:DealDamage(Target: Model, BaseDamage: number)
	local TargetController = CharacterController.Get(Target)
	if not TargetController then
		local Humanoid = Target:FindFirstChild("Humanoid") :: Humanoid
		if Humanoid then
			Humanoid.Health -= BaseDamage
		end
		return
	end

	local ModifiedDamage = BaseDamage
	for _, Entry in self.AttackModifiers do
		ModifiedDamage = Entry.Modifier(ModifiedDamage, {
			Target = Target,
			BaseDamage = BaseDamage,
		})
	end

	TargetController:TakeDamage(ModifiedDamage, self.Character, self.Character.PrimaryPart.CFrame.LookVector)

	self.StateManager:FireEvent(States.DAMAGE_DEALT, {
		Amount = ModifiedDamage,
		Target = Target,
		OriginalDamage = BaseDamage,
	})
end

function CharacterController:TakeDamage(Damage: number, Source: Model?, Direction: Vector3?)
	local ModifiedDamage = Damage
	for _, Entry in self.DamageModifiers do
		ModifiedDamage = Entry.Modifier(ModifiedDamage, {
			Source = Source,
			Direction = Direction,
			OriginalDamage = Damage,
		})
	end

	if self.StateManager:GetState(States.INVULNERABLE) then
		return
	end

	if self.StateManager:GetState(States.BLOCKING) then
		ModifiedDamage = ModifiedDamage * 0.5
	end

	self.Humanoid.Health -= ModifiedDamage

	self.StateManager:FireEvent(States.DAMAGE_TAKEN, {
		Amount = ModifiedDamage,
		Source = Source,
		Direction = Direction,
		WasBlocked = self.StateManager:GetState(States.BLOCKING),
		HealthPercent = self.Humanoid.Health / self.Humanoid.MaxHealth,
	})
end

function CharacterController:SetStates(StatesToSet: {[string]: boolean})
	for StateName, Value in StatesToSet do
		self.StateManager:SetState(StateName, Value)
	end
end

function CharacterController:GetDebugInfo(): {[string]: any}
	local ActiveStates = {}
	for StateName, _ in States do
		if self.StateManager:GetState(StateName) then
			table.insert(ActiveStates, StateName)
		end
	end

	local ActivePassives = {}
	for PassiveName, _ in self.PassiveController.ActivePassives do
		table.insert(ActivePassives, PassiveName)
	end

	return {
		CharacterName = self.Character.Name,
		IsPlayer = self.IsPlayer,
		Health = string.format("%.1f/%.1f", self.Humanoid.Health, self.Humanoid.MaxHealth),
		ActiveStates = ActiveStates,
		ActivePassives = ActivePassives,
		ModifierCounts = {
			Damage = #self.DamageModifiers,
			Attack = #self.AttackModifiers,
			Healing = #self.HealingModifiers,
			StaminaCost = #self.StaminaCostModifiers,
			Speed = #self.SpeedModifiers,
		},
	}
end

function CharacterController:Destroy()
	self.StateManager:Destroy()
	self.PassiveController:Destroy()

	if self.CombatController then
		self.CombatController:Destroy()
	end

	self.Maid:DoCleaning()
	Controllers[self.Character] = nil
end

function CharacterController.Get(Character: Model): ControllerType?
	return Controllers[Character]
end

return CharacterController