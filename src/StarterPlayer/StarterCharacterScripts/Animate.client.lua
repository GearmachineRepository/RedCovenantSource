-- humanoidAnimatePlayEmote.lua

local Figure = script.Parent
local Torso = Figure:WaitForChild("Torso")
local RightShoulder = Torso:WaitForChild("Right Shoulder")
local LeftShoulder = Torso:WaitForChild("Left Shoulder")
local RightHip = Torso:WaitForChild("Right Hip")
local LeftHip = Torso:WaitForChild("Left Hip")
local Humanoid = Figure:WaitForChild("Humanoid")
local Pose = "Standing"

local EMOTE_TRANSITION_TIME = 0.1

local UserAnimateScaleRunSuccess, UserAnimateScaleRunValue = pcall(function()
	return UserSettings():IsUserFeatureEnabled("UserAnimateScaleRun")
end)

local UserAnimateScaleRun = UserAnimateScaleRunSuccess and UserAnimateScaleRunValue

local function GetRigScale()
	if UserAnimateScaleRun then
		return Figure:GetScale()
	else
		return 1
	end
end

local CurrentAnim = ""
local CurrentAnimInstance = nil
local CurrentAnimTrack = nil
local CurrentAnimKeyframeHandler = nil
local CurrentAnimSpeed = 1.0
local AnimTable = {}
local AnimNames = {
	idle = 	{
				{ id = "http://www.roblox.com/asset/?id=180435571", weight = 9 },
				{ id = "http://www.roblox.com/asset/?id=180435792", weight = 1 }
			},
	walk = 	{
				{ id = "http://www.roblox.com/asset/?id=180426354", weight = 10 }
			},
	run = 	{
				{ id = "run.xml", weight = 10 }
			},
	jump = 	{
				{ id = "http://www.roblox.com/asset/?id=125750702", weight = 10 }
			},
	fall = 	{
				{ id = "http://www.roblox.com/asset/?id=180436148", weight = 10 }
			},
	climb = {
				{ id = "http://www.roblox.com/asset/?id=180436334", weight = 10 }
			},
	sit = 	{
				{ id = "http://www.roblox.com/asset/?id=178130996", weight = 10 }
			},
	toolnone = {
				{ id = "http://www.roblox.com/asset/?id=182393478", weight = 10 }
			},
	toolslash = {
				{ id = "http://www.roblox.com/asset/?id=129967390", weight = 10 }
--				{ id = "slash.xml", weight = 10 }
			},
	toollunge = {
				{ id = "http://www.roblox.com/asset/?id=129967478", weight = 10 }
			},
	wave = {
				{ id = "http://www.roblox.com/asset/?id=128777973", weight = 10 }
			},
	point = {
				{ id = "http://www.roblox.com/asset/?id=128853357", weight = 10 }
			},
	dance1 = {
				{ id = "http://www.roblox.com/asset/?id=182435998", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=182491037", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=182491065", weight = 10 }
			},
	dance2 = {
				{ id = "http://www.roblox.com/asset/?id=182436842", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=182491248", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=182491277", weight = 10 }
			},
	dance3 = {
				{ id = "http://www.roblox.com/asset/?id=182436935", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=182491368", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=182491423", weight = 10 }
			},
	laugh = {
				{ id = "http://www.roblox.com/asset/?id=129423131", weight = 10 }
			},
	cheer = {
				{ id = "http://www.roblox.com/asset/?id=129423030", weight = 10 }
			},
}
local Dances = {"dance1", "dance2", "dance3"}

-- Existence in this list signifies that it is an emote, the value indicates if it is a looping emote
local EmoteNames = { wave = false, point = false, dance1 = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

function ConfigureAnimationSet(name, fileList)
	if AnimTable[name] ~= nil then
		for _, connection in pairs(AnimTable[name].connections) do
			connection:Disconnect()
		end
	end
	AnimTable[name] = {}
	AnimTable[name].count = 0
	AnimTable[name].totalWeight = 0
	AnimTable[name].connections = {}

	-- check for config values
	local config = script:FindFirstChild(name)
	if config ~= nil then
--		print("Loading anims " .. name)
		table.insert(AnimTable[name].connections, config.ChildAdded:Connect(function()
			ConfigureAnimationSet(name, fileList)
		end))
		table.insert(AnimTable[name].connections, config.ChildRemoved:Connect(function()
			ConfigureAnimationSet(name, fileList)
		end))
		local idx = 1
		for _, childPart in pairs(config:GetChildren()) do
			if childPart:IsA("Animation") then
				table.insert(AnimTable[name].connections, childPart.Changed:Connect(function()
					ConfigureAnimationSet(name, fileList)
				end))
				AnimTable[name][idx] = {}
				AnimTable[name][idx].anim = childPart
				local weightObject = childPart:FindFirstChild("Weight")
				if weightObject == nil then
					AnimTable[name][idx].weight = 1
				else
					AnimTable[name][idx].weight = weightObject.Value
				end
				AnimTable[name].count = AnimTable[name].count + 1
				AnimTable[name].totalWeight = AnimTable[name].totalWeight + AnimTable[name][idx].weight
	--			print(name .. " [" .. idx .. "] " .. AnimTable[name][idx].anim.AnimationId .. " (" .. AnimTable[name][idx].weight .. ")")
				idx = idx + 1
			end
		end
	end

	-- fallback to defaults
	if AnimTable[name].count <= 0 then
		for idx, anim in pairs(fileList) do
			AnimTable[name][idx] = {}
			AnimTable[name][idx].anim = Instance.new("Animation")
			AnimTable[name][idx].anim.Name = name
			AnimTable[name][idx].anim.AnimationId = anim.id
			AnimTable[name][idx].weight = anim.weight
			AnimTable[name].count = AnimTable[name].count + 1
			AnimTable[name].totalWeight = AnimTable[name].totalWeight + anim.weight
--			print(name .. " [" .. idx .. "] " .. anim.id .. " (" .. anim.weight .. ")")
		end
	end
end

-- Setup animation objects
function ScriptChildModified(child)
	local fileList = AnimNames[child.Name]
	if fileList ~= nil then
		ConfigureAnimationSet(child.Name, fileList)
	end
end

script.ChildAdded:Connect(ScriptChildModified)
script.ChildRemoved:Connect(ScriptChildModified)

-- Clear any existing animation tracks
-- Fixes issue with characters that are moved in and out of the Workspace accumulating tracks
local Animator = if Humanoid then Humanoid:FindFirstChildOfClass("Animator") else nil
if Animator then
	local AnimTracks = Animator:GetPlayingAnimationTracks()
	for _, track in ipairs(AnimTracks) do
		track:Stop(0)
		track:Destroy()
	end
end


for name, fileList in pairs(AnimNames) do
	ConfigureAnimationSet(name, fileList)
end

-- ANIMATION

-- declarations
local ToolAnim = "None"
local ToolAnimTime = 0

local JumpAnimTime = 0
local JumpAnimDuration = 0.3

local ToolTransitionTime = 0.1
local FallTransitionTime = 0.3

-- functions

function StopAllAnimations()
	local oldAnim = CurrentAnim

	-- return to idle if finishing an emote
	if EmoteNames[oldAnim] ~= nil and EmoteNames[oldAnim] == false then
		oldAnim = "idle"
	end

	CurrentAnim = ""
	CurrentAnimInstance = nil
	if CurrentAnimKeyframeHandler ~= nil then
		CurrentAnimKeyframeHandler:Disconnect()
	end

	if CurrentAnimTrack ~= nil then
		CurrentAnimTrack:Stop()
		CurrentAnimTrack:Destroy()
		CurrentAnimTrack = nil
	end
	return oldAnim
end

function SetAnimationSpeed(speed)
	if speed ~= CurrentAnimSpeed then
		CurrentAnimSpeed = speed
		CurrentAnimTrack:AdjustSpeed(CurrentAnimSpeed)
	end
end

function KeyFrameReachedFunc(frameName)
	if frameName == "End" then

		local repeatAnim = CurrentAnim
		-- return to idle if finishing an emote
		if EmoteNames[repeatAnim] ~= nil and EmoteNames[repeatAnim] == false then
			repeatAnim = "idle"
		end

		local animSpeed = CurrentAnimSpeed
		PlayAnimation(repeatAnim, 0.0, Humanoid)
		SetAnimationSpeed(animSpeed)
	end
end

-- Preload animations
function PlayAnimation(animName, transitionTime, humanoid)

	local roll = math.random(1, AnimTable[animName].totalWeight)
	local idx = 1
	while roll > AnimTable[animName][idx].weight do
		roll = roll - AnimTable[animName][idx].weight
		idx = idx + 1
	end
--		print(animName .. " " .. idx .. " [" .. origRoll .. "]")
	local anim = AnimTable[animName][idx].anim

	-- switch animation
	if anim ~= CurrentAnimInstance then

		if CurrentAnimTrack ~= nil then
			CurrentAnimTrack:Stop(transitionTime)
			CurrentAnimTrack:Destroy()
		end

		CurrentAnimSpeed = 1.0

		-- load it to the humanoid; get AnimationTrack
		CurrentAnimTrack = humanoid:LoadAnimation(anim)
		CurrentAnimTrack.Priority = Enum.AnimationPriority.Core

		-- play the animation
		CurrentAnimTrack:Play(transitionTime)
		CurrentAnim = animName
		CurrentAnimInstance = anim

		-- set up keyframe name triggers
		if CurrentAnimKeyframeHandler ~= nil then
			CurrentAnimKeyframeHandler:Disconnect()
		end
		CurrentAnimKeyframeHandler = CurrentAnimTrack.KeyframeReached:Connect(KeyFrameReachedFunc)

	end

end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

local ToolAnimName = ""
local ToolAnimTrack = nil
local ToolAnimInstance = nil
local CurrentToolAnimKeyframeHandler = nil

function ToolKeyFrameReachedFunc(frameName)
	if frameName == "End" then
--		print("Keyframe : ".. frameName)
		PlayToolAnimation(ToolAnimName, 0.0, Humanoid)
	end
end


function PlayToolAnimation(animName, transitionTime, humanoid, priority)

		local roll = math.random(1, AnimTable[animName].totalWeight)
		local idx = 1
		while roll > AnimTable[animName][idx].weight do
			roll = roll - AnimTable[animName][idx].weight
			idx = idx + 1
		end
--		print(animName .. " * " .. idx .. " [" .. origRoll .. "]")
		local anim = AnimTable[animName][idx].anim

		if ToolAnimInstance ~= anim then

			if ToolAnimTrack ~= nil then
				ToolAnimTrack:Stop()
				ToolAnimTrack:Destroy()
				transitionTime = 0
			end

			-- load it to the humanoid; get AnimationTrack
			ToolAnimTrack = humanoid:LoadAnimation(anim)
			if priority then
				ToolAnimTrack.Priority = priority
			end

			-- play the animation
			ToolAnimTrack:Play(transitionTime)
			ToolAnimName = animName
			ToolAnimInstance = anim

			CurrentToolAnimKeyframeHandler = ToolAnimTrack.KeyframeReached:Connect(ToolKeyFrameReachedFunc)
		end
end

function StopToolAnimations()
	local oldAnim = ToolAnimName

	if CurrentToolAnimKeyframeHandler ~= nil then
		CurrentToolAnimKeyframeHandler:Disconnect()
	end

	ToolAnimName = ""
	ToolAnimInstance = nil
	if ToolAnimTrack ~= nil then
		ToolAnimTrack:Stop()
		ToolAnimTrack:Destroy()
		ToolAnimTrack = nil
	end


	return oldAnim
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------


function OnRunning(speed)
	speed /= GetRigScale()

	if speed > 0.01 then
		PlayAnimation("walk", 0.1, Humanoid)
		if CurrentAnimInstance and CurrentAnimInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
			SetAnimationSpeed(speed / 14.5)
		end
		Pose = "Running"
	else
		if EmoteNames[CurrentAnim] == nil then
			PlayAnimation("idle", 0.1, Humanoid)
			Pose = "Standing"
		end
	end
end

function OnDied()
	Pose = "Dead"
end

function OnJumping()
	PlayAnimation("jump", 0.1, Humanoid)
	JumpAnimTime = JumpAnimDuration
	Pose = "Jumping"
end

function OnClimbing(speed)
	speed /= GetRigScale()

	PlayAnimation("climb", 0.1, Humanoid)
	SetAnimationSpeed(speed / 12.0)
	Pose = "Climbing"
end

function OnGettingUp()
	Pose = "GettingUp"
end

function OnFreeFall()
	if JumpAnimTime <= 0 then
		PlayAnimation("fall", FallTransitionTime, Humanoid)
	end
	Pose = "FreeFall"
end

function OnFallingDown()
	Pose = "FallingDown"
end

function OnSeated()
	Pose = "Seated"
end

function OnPlatformStanding()
	Pose = "PlatformStanding"
end

function OnSwimming(speed)
	if speed > 0 then
		Pose = "Running"
	else
		Pose = "Standing"
	end
end

function GetTool()
	for _, kid in ipairs(Figure:GetChildren()) do
		if kid.className == "Tool" then
			return kid
		end
	end
	return nil
end

function GetToolAnim(tool)
	for _, c in ipairs(tool:GetChildren()) do
		if c.Name == "toolanim" and c.className == "StringValue" then
			return c
		end
	end
	return nil
end

function AnimateTool()

	if ToolAnim == "None" then
		PlayToolAnimation("toolnone", ToolTransitionTime, Humanoid, Enum.AnimationPriority.Idle)
		return
	end

	if ToolAnim == "Slash" then
		PlayToolAnimation("toolslash", 0, Humanoid, Enum.AnimationPriority.Action)
		return
	end

	if ToolAnim == "Lunge" then
		PlayToolAnimation("toollunge", 0, Humanoid, Enum.AnimationPriority.Action)
		return
	end
end

local LastTick = 0

function Move(time)
	local amplitude = 1
	local frequency = 1
  	local deltaTime = time - LastTick
  	LastTick = time

	local climbFudge = 0
	local setAngles = false

  	if JumpAnimTime > 0 then
  		JumpAnimTime = JumpAnimTime - deltaTime
  	end

	if Pose == "FreeFall" and JumpAnimTime <= 0 then
		PlayAnimation("fall", FallTransitionTime, Humanoid)
	elseif Pose == "Seated" then
		PlayAnimation("sit", 0.5, Humanoid)
		return
	elseif Pose == "Running" then
		PlayAnimation("walk", 0.1, Humanoid)
	elseif Pose == "Dead" or Pose == "GettingUp" or Pose == "FallingDown" or Pose == "Seated" or Pose == "PlatformStanding" then
--		print("Wha " .. Pose)
		StopAllAnimations()
		amplitude = 0.1
		frequency = 1
		setAngles = true
	end

	if setAngles then
		local desiredAngle = amplitude * math.sin(time * frequency)

		RightShoulder:SetDesiredAngle(desiredAngle + climbFudge)
		LeftShoulder:SetDesiredAngle(desiredAngle - climbFudge)
		RightHip:SetDesiredAngle(-desiredAngle)
		LeftHip:SetDesiredAngle(-desiredAngle)
	end

	-- Tool Animation handling
	local tool = GetTool()
	if tool and tool:FindFirstChild("Handle") then

		local animStringValueObject = GetToolAnim(tool)

		if animStringValueObject then
			ToolAnim = animStringValueObject.Value
			-- message received, delete StringValue
			animStringValueObject.Parent = nil
			ToolAnimTime = time + .3
		end

		if time > ToolAnimTime then
			ToolAnimTime = 0
			ToolAnim = "None"
		end

		AnimateTool()
	else
		StopToolAnimations()
		ToolAnim = "None"
		ToolAnimInstance = nil
		ToolAnimTime = 0
	end
end

-- connect events
Humanoid.Died:Connect(OnDied)
Humanoid.Running:Connect(OnRunning)
Humanoid.Jumping:Connect(OnJumping)
Humanoid.Climbing:Connect(OnClimbing)
Humanoid.GettingUp:Connect(OnGettingUp)
Humanoid.FreeFalling:Connect(OnFreeFall)
Humanoid.FallingDown:Connect(OnFallingDown)
Humanoid.Seated:Connect(OnSeated)
Humanoid.PlatformStanding:Connect(OnPlatformStanding)
Humanoid.Swimming:Connect(OnSwimming)

---- setup emote chat hook
game:GetService("Players").LocalPlayer.Chatted:Connect(function(msg)
	local emote = ""
	if msg == "/e dance" then
		emote = Dances[math.random(1, #Dances)]
	elseif string.sub(msg, 1, 3) == "/e " then
		emote = string.sub(msg, 4)
	elseif string.sub(msg, 1, 7) == "/emote " then
		emote = string.sub(msg, 8)
	end

	if Pose == "Standing" and EmoteNames[emote] ~= nil then
		PlayAnimation(emote, 0.1, Humanoid)
	end

end)

local PlayEmote = Instance.new("BindableFunction")
PlayEmote.Name = "PlayEmote"
PlayEmote.Parent = script

-- emote bindable hook
PlayEmote.OnInvoke = function(emote)
	-- Only play emotes when idling
	if Pose ~= "Standing" then
		return
	end
	if EmoteNames[emote] ~= nil then
		-- Default emotes
		PlayAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)

		return true, CurrentAnimTrack
	end

	-- Return false to indicate that the emote could not be played
	return false
end
-- main program

-- initialize to idle
PlayAnimation("idle", 0.1, Humanoid)
Pose = "Standing"

while Figure.Parent ~= nil do
	task.wait(0.1)
	Move(os.clock())
end