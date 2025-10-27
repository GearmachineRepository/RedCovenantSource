--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packets = require(Shared.Networking.Packets)
local ShapecastHitbox = require(Shared.Hitbox.ShapecastHitbox)

local ClientCooldowns = {}

local function IsOnClientCooldown(CooldownName: string): boolean
	if ClientCooldowns[CooldownName] then
		return tick() < ClientCooldowns[CooldownName]
	end
	return false
end

local function StartClientCooldown(CooldownName: string, Duration: number)
	ClientCooldowns[CooldownName] = tick() + Duration
end

local function RequestAttack()
	-- Client-side cooldown check (optimistic)
	if IsOnClientCooldown("Attack") then
		return
	end

	-- Start cooldown immediately
	StartClientCooldown("Attack", 0.2)

	-- Optimistically play animation
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")
	if not Animator then return end

	-- Load attack animation
	local AttackAnim = Instance.new("Animation")
	AttackAnim.AnimationId = "rbxassetid://0000000" -- Replace with actual ID

	local AnimTrack = Animator:LoadAnimation(AttackAnim)

	-- Send request to server (doesn't wait for response)
	Packets.RequestAttack:Fire()

	-- Setup hitbox detection
	local WeaponModel = Character:FindFirstChild("Weapon")
	if not WeaponModel then return end

	local Hitbox = ShapecastHitbox.new(WeaponModel)
	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterDescendantsInstances = {Character}
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	Hitbox.RaycastParams = RaycastParams

	local HitTargets = {}

	Hitbox:OnHit(function(RaycastResult, _) -- Segment
		local HitPart = RaycastResult.Instance
		local Target = HitPart:FindFirstAncestorOfClass("Model")

		if Target and not HitTargets[Target] then
			HitTargets[Target] = true

			-- Immediate non-committal feedback
			local HitSound = Instance.new("Sound")
			HitSound.SoundId = "rbxassetid://0000000" -- Hit sound
			HitSound.Parent = HitPart
			HitSound:Play()
			HitSound.Ended:Connect(function()
				HitSound:Destroy()
			end)

			-- Light VFX (spark, no blood)
			local Spark = ReplicatedStorage.Assets.Effects.HitSpark:Clone()
			Spark.Position = RaycastResult.Position
			Spark.Parent = workspace.Effects

			-- Determine hit location
			local HitLocation = "Torso"
			local PartName = HitPart.Name:lower()
			if PartName:match("head") then
				HitLocation = "Head"
			elseif PartName:match("leg") or PartName:match("foot") then
				HitLocation = "Legs"
			end

			-- Send hit to server for validation
			Packets.CombatHit:Fire(Target, HitLocation, RaycastResult.Position, tick())
		end
	end)

	-- Animation markers control hitbox
	local HitboxActive = false

	AnimTrack:GetMarkerReachedSignal("HitboxStart"):Connect(function()
		HitboxActive = true
		Hitbox:HitStart()
	end)

	AnimTrack:GetMarkerReachedSignal("HitboxEnd"):Connect(function()
		if HitboxActive then
			Hitbox:HitStop()
			Hitbox:Destroy()
			HitboxActive = false
		end
	end)

	AnimTrack.Stopped:Connect(function()
		if HitboxActive then
			Hitbox:HitStop()
			Hitbox:Destroy()
		end
	end)

	AnimTrack:Play()
end

-- Server can cancel animation if invalid
Packets.CancelAttack.OnClientEvent:Connect(function()
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")
	if not Animator then return end

	-- Stop all attack animations
	for _, Track in Animator:GetPlayingAnimationTracks() do
		if Track.Name:match("Attack") then
			Track:Stop()
		end
	end
end)

-- Server confirms hit with damage for committal feedback
Packets.CombatHitConfirmed.OnClientEvent:Connect(function(Target: Model, Damage: number, WasBlocked: boolean, _: string) -- HitLocation
	if WasBlocked then
		-- Show block feedback
		local BlockSound = Instance.new("Sound")
		BlockSound.SoundId = "rbxassetid://0000000" -- Block sound
		BlockSound.Parent = Target.PrimaryPart
		BlockSound:Play()

		local BlockSpark = ReplicatedStorage.Assets.Effects.BlockSpark:Clone()
		BlockSpark.Position = Target.PrimaryPart.Position
		BlockSpark.Parent = workspace.Effects
	else
		-- Show damage feedback (committal)
		local BloodEffect = ReplicatedStorage.Assets.Effects.Blood:Clone()
		BloodEffect.Position = Target.PrimaryPart.Position
		BloodEffect.Parent = workspace.Effects

		-- Damage number
		local DamageLabel = ReplicatedStorage.Assets.UI.DamageNumber:Clone()
		DamageLabel.Text = tostring(math.floor(Damage))
		DamageLabel.Parent = Target.PrimaryPart
	end
end)

-- Input binding
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
	if GameProcessed then return end

	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		RequestAttack()
	end
end)