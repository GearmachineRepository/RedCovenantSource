--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local StatesModule = require(Shared.Configurations.States)
local States = StatesModule.States

local StateHandlers = {}

function StateHandlers.Setup(Controller: any)
	local StateManager = Controller.StateManager
	local Character = Controller.Character

	-- Ragdoll handler
	StateManager:OnStateChanged(States.RAGDOLLED, function(IsRagdolled)
		if IsRagdolled then
			print(Character.Name .. " ragdolled")
			-- TODO: Enable ragdoll physics
		else
			print(Character.Name .. " unragdolled")
			-- TODO: Disable ragdoll physics
		end
	end)

	-- Stunned handler
	StateManager:OnStateChanged(States.STUNNED, function(IsStunned)
		if IsStunned then
			Controller.Humanoid.WalkSpeed = 0
		else
			Controller.Humanoid.WalkSpeed = 16
		end
	end)

	-- Attacking handler
	StateManager:OnStateChanged(States.ATTACKING, function(IsAttacking)

		if IsAttacking then
			print(Character.Name .. " started attacking")
			-- TODO: Play attack animation
		else
			print(Character.Name .. " stopped attacking")
			-- TODO: Stop attack animation
		end
	end)

	-- Invulnerable handler
	StateManager:OnStateChanged(States.INVULNERABLE, function(IsInvulnerable)
		if IsInvulnerable then
			local ForceField = Instance.new("ForceField")
			ForceField.Parent = Character
		else
			local ForceField = Character:FindFirstChildOfClass("ForceField")
			if ForceField then
				ForceField:Destroy()
			end
		end
	end)


end

return StateHandlers