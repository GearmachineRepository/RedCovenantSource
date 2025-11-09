--!strict

local HitDetection = {}

function HitDetection.GetHitLocation(HitPart: BasePart): string
	local PartName = HitPart.Name:lower()

	if PartName:match("head") then
		return "Head"
	elseif PartName:match("leg") or PartName:match("foot") or PartName:match("lower") then
		return "Legs"
	else
		return "Torso"
	end
end

function HitDetection.ValidateDistance(Attacker: Model, Target: Model, MaxRange: number, Tolerance: number?): boolean
	if not Attacker.PrimaryPart or not Target.PrimaryPart then
		return false
	end

	local AttackerPos = Attacker.PrimaryPart.Position
	local TargetPos = Target.PrimaryPart.Position
	local Distance = (AttackerPos - TargetPos).Magnitude

	local RangeTolerance = Tolerance or 2.0

	return Distance <= (MaxRange + RangeTolerance)
end

function HitDetection.ValidateTimestamp(ClientTimestamp: number, Tolerance: number?): boolean
	local ServerTime = tick()
	local Latency = ServerTime - ClientTimestamp

	local LatencyTolerance = Tolerance or 0.1

	return math.abs(Latency) <= LatencyTolerance
end

function HitDetection.IsInFrontCone(Attacker: Model, Target: Model, ConeAngle: number?): boolean
	if not Attacker.PrimaryPart or not Target.PrimaryPart then
		return false
	end

	local AttackerLook = Attacker.PrimaryPart.CFrame.LookVector
	local DirectionToTarget = (Target.PrimaryPart.Position - Attacker.PrimaryPart.Position).Unit

	local DotProduct = AttackerLook:Dot(DirectionToTarget)
	local Angle = math.deg(math.acos(DotProduct))

	local MaxAngle = (ConeAngle or 140) / 2

	return Angle <= MaxAngle
end

function HitDetection.CalculateForwardVelocity(Character: Model): number
	if not Character.PrimaryPart then
		return 0
	end

	local Velocity = Character.PrimaryPart.AssemblyLinearVelocity
	local LookVector = Character.PrimaryPart.CFrame.LookVector

	return LookVector:Dot(Velocity)
end

function HitDetection.CreateRaycastParams(Attacker: Model, IgnoreList: {Instance}?): RaycastParams
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude

	local FilterList = {Attacker}
	if IgnoreList then
		for _, Instance in IgnoreList do
			table.insert(FilterList, Instance)
		end
	end

	Params.FilterDescendantsInstances = FilterList

	return Params
end

return HitDetection