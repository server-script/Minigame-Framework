local ragdollService = {}

-- REQUIREMENTS --
local runService = game:GetService("RunService")

-- VARIABLES --
--/Settings
local TARGET_MOTORS = {
	LeftWrist = true,
	RightWrist = true,
	LeftElbow = true,
	RightElbow = true,
	LeftShoulder = true,
	RightShoulder = true,
	LeftAnkle = true,
	LeftKnee = true,
	Waist = true,
	LeftHip = true,
	RightAnkle = true,
	RightKnee = true,
	--Root = true,
	RightHip = true,
	Neck = true
}

--/References
local enableRagdollFunction = script.EnableRagdoll
local disableRagdollFunction = script.DisableRagdoll
local applyImpulseRemote = script.ApplyImpulse

--/Holders
local unragdollMarks = {}

-- PUBLIC METHODS --
function InitializeClient()
	enableRagdollFunction.OnClientInvoke = function()
		ClientEnableRagdoll()
	end
	disableRagdollFunction.OnClientInvoke = function()
		ClientDisableRagdoll()
	end
	
	applyImpulseRemote.OnClientEvent:Connect(ClientApplyImpulse)
end

function InitializeServer()
	for _, player in pairs(game.Players:GetPlayers()) do
		OnServerPlayerAdded(player)
	end
	game.Players.PlayerAdded:Connect(OnServerPlayerAdded)
end

function OnServerPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		ragdollService.AttachRagdoll(player)
	end)
	
	coroutine.wrap(function()
		if player.Character and player.Character:IsDescendantOf(workspace) then
			ragdollService.AttachRagdoll(player)
		end
	end)()
end

function ragdollService.AttachRagdoll(player)
	if not player.Character then return end
	repeat wait() until player.Character:IsDescendantOf(workspace)
	local character = player.Character
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.RequiresNeck = false


	local newRagdolls = script.CharacterConstraints.RagdollConstraints:Clone()
	for _, constraint in pairs(newRagdolls:GetDescendants()) do
		--Collision constraint

		if constraint:IsA("NoCollisionConstraint") then
			constraint.Part0 = character:WaitForChild(constraint.Part0.Name)
			constraint.Part1 = character:WaitForChild(constraint.Part1.Name)
		elseif constraint:IsA("Constraint") then
			constraint.Attachment0 = character:WaitForChild(constraint.Attachment0.Parent.Name):WaitForChild(constraint.Attachment0.Name)
			constraint.Attachment1 = character:WaitForChild(constraint.Attachment1.Parent.Name):WaitForChild(constraint.Attachment1.Name)
		end

		if constraint:IsA("ObjectValue") and constraint.Parent:IsA("Constraint") then
			local a = character:WaitForChild(constraint.Value.Parent.Name):WaitForChild(constraint.Value.Name)
			if not a then warn("Could not find", constraint.Value.Name) end
			constraint.Value = a
		end
	end
	newRagdolls.Parent = character
	
	character.ChildRemoved:Connect(function()
		local partsCount = 0
		for _, part in pairs(character:GetChildren()) do
			if part:IsA("BasePart") then
				partsCount += 1
			end
		end
		
		if partsCount == 0 and character:FindFirstChild("Humanoid") then
			character.Humanoid.Health = 0
		end
	end)
end

function ragdollService.ServerEnableRagdoll(player)
	local character = player.Character
	if not character or not character:IsDescendantOf(workspace)then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end
	
	local ragdollConstraints = character:FindFirstChild("RagdollConstraints")
	if not ragdollConstraints then return end
	
	enableRagdollFunction:InvokeClient(player)
	
	humanoid.AutoRotate = false
	rootPart.CanCollide = false
	
	for _, motor in pairs(character:GetDescendants()) do
		if motor:IsA("Motor6D") and TARGET_MOTORS[motor.Name] then
			motor.Enabled = false
		end
		
		if motor:IsA("BasePart") and not (motor == humanoid.RootPart) then
			motor.CanCollide = true
		end
	end
	
	if ragdollConstraints then
		for _,constraint in pairs(ragdollConstraints:GetChildren()) do
			if constraint:IsA("Constraint") then
				local rigidJoint = constraint.RigidJoint.Value
				rigidJoint.Enabled = false
			end
		end
	end
end

function ragdollService.ServerDisableRagdoll(player)
	local character = player.Character
	if not character or not character:IsDescendantOf(workspace) then return end

	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	local ragdollConstraints = character:FindFirstChild("RagdollConstraints")
	if not ragdollConstraints then return end

	disableRagdollFunction:InvokeClient(player)

	humanoid.AutoRotate = true
	rootPart.CanCollide = true
	
	for _, motor in pairs(character:GetDescendants()) do
		if motor:IsA("Motor6D") and TARGET_MOTORS[motor.Name] then
			motor.Enabled = true
		end
	end
	
	if ragdollConstraints then
		for _,constraint in pairs(ragdollConstraints:GetChildren()) do
			if constraint:IsA("Constraint") then
				local rigidJoint = constraint.RigidJoint.Value
				rigidJoint.Enabled = true
			end
		end
	end
end

function ragdollService.RagdollPushImpulse(player, impulse, position)
	local character = player.Character
	if not character or not character:IsDescendantOf(workspace)then return end

	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end
	
	if not ragdollService.IsRagdolled(player) then
		ragdollService.ServerEnableRagdoll(player)
	end
	
	applyImpulseRemote:FireClient(player, impulse, position)
end

function ragdollService.RagdollPushVelocity(player, velocity, position)
	local character = player.Character
	if not character or not character:IsDescendantOf(workspace) then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local impulse = velocity * GetCharacterMass(character)
	
	ragdollService.RagdollPushImpulse(player, impulse, position)
end

function ragdollService.IsRagdolled(player)
	local character = player.Character
	if not character or not character:IsDescendantOf(workspace) then return false end

	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return false end
	
	return humanoid:GetState() == Enum.HumanoidStateType.Ragdoll
end

function ragdollService.MarkForUnragdoll(player, delayTime)
	if unragdollMarks[player] then
		unragdollMarks[player] = nil
	end
	
	unragdollMarks[player] = {startTime = workspace:GetServerTimeNow(), delayTime = delayTime}
end

function ragdollService.RemoveMark(player)
	if unragdollMarks[player] then
		unragdollMarks[player] = nil
	end
end

-- PRIVATE FUNCTIONS --
function GetCharacterMass(character)
	local mass = 0
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			mass += part:GetMass()
		end
	end
	return mass
end

function ClientApplyImpulse(impulse, position)
	local localPlayer = game.Players.LocalPlayer
	local character = localPlayer.Character
	if not character or not character:IsDescendantOf(workspace) then return false end

	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return false end
	
	if position then
		rootPart:ApplyImpulseAtPosition(impulse, position)
	else
		rootPart:ApplyImpulse(impulse, position)
	end
end

function ClientDisableRagdoll()
	local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
	local animate = game.Players.LocalPlayer.Character:FindFirstChild("Animate")
	animate.Disabled = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

function ClientEnableRagdoll(impulse, position)
	local localPlayer = game.Players.LocalPlayer
	local character = localPlayer.Character
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local animate = character:FindFirstChild("Animate")
	animate.Disabled = true
	local activeTracks = humanoid.Animator:GetPlayingAnimationTracks()
	for _,v in pairs(activeTracks) do
		v:AdjustWeight(0)
		v:Stop()
	end
	humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
end

function UpdateMarks()
	for player, markInfo in pairs(unragdollMarks) do
		if workspace:GetServerTimeNow() - markInfo.startTime < markInfo.delayTime then continue end
		
		if ragdollService.IsRagdolled(player) then
			ragdollService.ServerDisableRagdoll(player)
		end
	end
end

-- INITIALIZE --
function Initialize()
	if runService:IsServer() then
		InitializeServer()
		runService.Stepped:Connect(UpdateMarks)
	end

	if runService:IsClient() then
		InitializeClient()
	end
end
Initialize()

return ragdollService
