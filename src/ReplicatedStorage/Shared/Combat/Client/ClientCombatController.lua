--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packets = require(Shared.Networking.Packets)
local Maid = require(Shared.General.Maid)
local Promise = require(Shared.Packages.Promise)

export type ClientCombatController = {
	Character: Model,
	Humanoid: Humanoid,
	Maid: Maid.MaidSelf,
	CurrentWeaponType: string?,
	CurrentCombo: number,
	IsAttacking: boolean,
	HitboxActive: boolean,
	HitTargets: {[Model]: boolean},
	AnimationTracks: {[string]: AnimationTrack},

	EquipWeapon: (self: ClientCombatController, WeaponType: string) -> typeof(Promise),
	UnequipWeapon: (self: ClientCombatController) -> (),
	RequestAction: (self: ClientCombatController, ActionType: string, ComboIndex: number?) -> (),
	PlayAnimation: (self: ClientCombatController, AnimationId: string) -> AnimationTrack?,
	StartHitboxDetection: (self: ClientCombatController, Duration: number) -> (),
	StopHitboxDetection: (self: ClientCombatController) -> (),
	RegisterHit: (self: ClientCombatController, Target: Model, HitLocation: string, HitPosition: Vector3) -> (),
	Destroy: (self: ClientCombatController) -> (),
}

local ClientCombatController = {}
ClientCombatController.__index = ClientCombatController

function ClientCombatController.new(Character: Model): ClientCombatController
	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid

	local self = setmetatable({
		Character = Character,
		Humanoid = Humanoid,
		Maid = Maid.new(),
		CurrentWeaponType = nil,
		CurrentCombo = 0,
		IsAttacking = false,
		HitboxActive = false,
		HitTargets = {},
		AnimationTracks = {},
	}, ClientCombatController)

	self.Maid:GiveTask(Packets.RollbackAction.OnClientEvent:Connect(function()
		self.IsAttacking = false
		self:StopHitboxDetection()

		for _, Track in self.AnimationTracks do
			Track:Stop()
		end
	end))

	return (self :: any) :: ClientCombatController
end

function ClientCombatController:EquipWeapon(WeaponType: string): typeof(Promise)
	return Promise.new(function(Resolve, Reject)
		self:UnequipWeapon()

		local WeaponModulePath = Shared.Combat.Weapons:FindFirstChild(WeaponType)
		if not WeaponModulePath then
			Reject("Weapon module not found")
			return
		end

		self.CurrentWeaponType = WeaponType
		self.CurrentCombo = 0

		Resolve()
	end)
end

function ClientCombatController:UnequipWeapon()
	self.CurrentWeaponType = nil
	self.CurrentCombo = 0
	self.IsAttacking = false
	self:StopHitboxDetection()

	for _, Track in self.AnimationTracks do
		Track:Stop()
		Track:Destroy()
	end

	table.clear(self.AnimationTracks)
end

function ClientCombatController:RequestAction(ActionType: string, ComboIndex: number?)
	if self.IsAttacking then return end
	if not self.CurrentWeaponType then return end

	local Index = ComboIndex or 1

	self.IsAttacking = true
	Packets.RequestCombatAction:Fire(ActionType, Index)

	local WeaponModule = require(Shared.Combat.Weapons[self.CurrentWeaponType])

	if ActionType == "LightAttack" then
		local AnimName = "LightAttack" .. Index
		local AnimId = WeaponModule.Animations[AnimName]

		if AnimId then
			local Track = self:PlayAnimation(AnimId)

			if Track then
				local Window = WeaponModule.HitboxWindows[AnimName]
				if Window then
					task.delay(Window.Start, function()
						self:StartHitboxDetection(Window.End - Window.Start)
					end)
				end

				Track.Ended:Connect(function()
					self.IsAttacking = false
				end)
			end
		end
	end
end

function ClientCombatController:PlayAnimation(AnimationId: string): AnimationTrack?
	if not AnimationId or AnimationId == "rbxassetid://0" then
		return nil
	end

	if self.AnimationTracks[AnimationId] then
		local Track = self.AnimationTracks[AnimationId]
		Track:Play()
		return Track
	end

	local Animation = Instance.new("Animation")
	Animation.AnimationId = AnimationId

	local Track = self.Humanoid:LoadAnimation(Animation)
	Track:Play()

	self.AnimationTracks[AnimationId] = Track

	return Track
end

function ClientCombatController:StartHitboxDetection(Duration: number)
	self.HitboxActive = true
	table.clear(self.HitTargets)

	local Weapon = self.Character:FindFirstChild("Weapon")
	if not Weapon or not Weapon:IsA("BasePart") then
		return
	end

	local LastPosition = Weapon.Position

	local Connection
	Connection = RunService.Heartbeat:Connect(function()
		if not self.HitboxActive then
			Connection:Disconnect()
			return
		end

		local CurrentPosition = Weapon.Position
		local Direction = (CurrentPosition - LastPosition)
		local Distance = Direction.Magnitude

		if Distance > 0.1 then
			local RaycastParams = RaycastParams.new()
			RaycastParams.FilterDescendantsInstances = {self.Character}
			RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

			local Result = workspace:Raycast(LastPosition, Direction, RaycastParams)

			if Result then
				local TargetChar = Result.Instance:FindFirstAncestorOfClass("Model")

				if TargetChar and TargetChar:FindFirstChild("Humanoid") and not self.HitTargets[TargetChar] then
					self.HitTargets[TargetChar] = true

					local HitLocation = "Torso"
					local PartName = Result.Instance.Name:lower()
					if PartName:match("head") then
						HitLocation = "Head"
					elseif PartName:match("leg") or PartName:match("foot") then
						HitLocation = "Legs"
					end

					self:RegisterHit(TargetChar, HitLocation, Result.Position)
				end
			end
		end

		LastPosition = CurrentPosition
	end)

	self.Maid:GiveTask(Connection)

	task.delay(Duration, function()
		self:StopHitboxDetection()
	end)
end

function ClientCombatController:StopHitboxDetection()
	self.HitboxActive = false
end

function ClientCombatController:RegisterHit(Target: Model, HitLocation: string, HitPosition: Vector3)
	Packets.CombatHitRegistered:Fire(Target, HitLocation, HitPosition)
end

function ClientCombatController:Destroy()
	self:UnequipWeapon()
	self.Maid:DoCleaning()
end

return ClientCombatController