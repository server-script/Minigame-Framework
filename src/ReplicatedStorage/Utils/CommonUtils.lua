local CommonUtils = {}

local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

local playerEliminatedEvent = Instance.new("BindableEvent")
CommonUtils.PlayerEliminated = playerEliminatedEvent.Event

function CommonUtils.GetPlayerRootPart(player)
	local character = player.Character
	if not character or not character.Parent == workspace then return end
	return character:FindFirstChild("HumanoidRootPart")
end

function CommonUtils.GetPlayerHumanoid(player)
	local character = player.Character
	if not character or not character.Parent == workspace then return end
	return character:FindFirstChild("Humanoid")
end

function CommonUtils.WaitPlayerRootPart(player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("HumanoidRootPart")
end

function CommonUtils.WaitPlayerHumanoid(player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("Humanoid")
end

function CommonUtils.IsDestroyed(instance)
	local connection = instance:GetPropertyChangedSignal("Parent"):Connect(function() end)
	return function()
		return not connection.Connected
	end
end

function CommonUtils.OnDestroyed(instance, callback)
	local connection
	connection = instance:GetPropertyChangedSignal("Parent"):Connect(function()
		runService.Heartbeat:Wait()
		if not connection.Connected then
			callback()
		end
	end)
	return connection
end

function CommonUtils.WaitForAncestor(part, anchestor, maxWait)
	maxWait = maxWait or math.huge
	local initialTime = time()
	repeat 
		part.AncestryChanged:Wait() 
	until part:IsDescendantOf(anchestor) or time() - initialTime > maxWait
end

function CommonUtils.ConditionRaycast(origin, direction, raycastParams, condition)
	local raycastResult = workspace:Raycast(origin, direction, raycastParams)

	if raycastResult == nil or condition(raycastResult.Instance) then
		return raycastResult
	end
	
	local newParams = RaycastParams.new()
	local newIgnoreList = {raycastResult.Instance}
	for _, item in pairs(raycastParams.FilterDescendantsInstances) do
		table.insert(newIgnoreList, item)
	end
	newParams.FilterDescendantsInstances = newIgnoreList
	
	local intersection = raycastResult.Position

	direction = direction - (intersection - origin)
	origin = intersection
	
	return CommonUtils.ConditionRaycast(origin, direction, newParams, condition)
end

function CommonUtils.GetAnimatorAnimationTrack(animator, animationId)
	local activeTracks = animator:GetPlayingAnimationTracks()
	for _, track in pairs(activeTracks) do
		local trackId = track.Animation.AnimationId
		if trackId == animationId then return track end
	end
end

function CommonUtils.TweenNumberSequence(object, tweenInfo, propertyName, target)
	local propertyHolder = Instance.new("NumberValue")

	local tween = tweenService:Create(propertyHolder, tweenInfo, {Value = target})

	local updateLoop
	if runService:IsServer() then
		updateLoop = runService.Stepped:Connect(function()
			object[propertyName] = NumberSequence.new(propertyHolder.Value)
		end)
	else
		updateLoop = runService.RenderStepped:Connect(function()
			object[propertyName] = NumberSequence.new(propertyHolder.Value)
		end)
	end

	local tweenEnd
	tweenEnd = tween.Completed:Connect(function()
		tweenEnd:Disconnect()
		updateLoop:Disconnect()
	end)
	
	tween:Play()
	return tween
end

function CommonUtils.GetPlayerCameraHeight(player)
	local rootPart = CommonUtils.GetPlayerRootPart(player)
	if not rootPart then return end

	local ORIGIN_OFFSET = Vector3.new(0, 1.5, 0)
	local HUMANOID_ROOT_PART_SIZE = Vector3.new(2, 2, 1)
	local rootPartSizeOffset = (rootPart.Size.Y - HUMANOID_ROOT_PART_SIZE.Y)/2
	local heightOffset = ORIGIN_OFFSET + Vector3.new(0, rootPartSizeOffset, 0)
	return rootPart.Position + heightOffset
end

function CommonUtils.DictionaryLength(dictionary)
	local i = 0
	for _, _ in pairs(dictionary) do
		i+=1
	end
	return i
end

function CommonUtils.FindFirstChildChain(parent, ...)
	if parent == CommonUtils then
		error("Experted . not : calling FindFirstChildChain")
	end
	
	local nextChild = parent
	for _, name in pairs({...}) do
		nextChild = nextChild:FindFirstChild(name)
		if not nextChild then return nil, name end
	end
	return nextChild
end


function SetupPlayerEliminatedEvent()
	local function OnCharacterAdded(player, character)
		local humanoid = character:WaitForChild("Humanoid")
		local destroyedConnection
		local diedConnection
		diedConnection = humanoid.Died:Connect(function()
			playerEliminatedEvent:Fire(player)
			diedConnection:Disconnect()
			destroyedConnection:Disconnect()
		end)
		destroyedConnection = CommonUtils.OnDestroyed(character, function()
			playerEliminatedEvent:Fire(player)
			diedConnection:Disconnect()
			destroyedConnection:Disconnect()
		end)
	end
	
	local function OnPlayerAdded(player)
		player.CharacterAdded:Connect(function(character)
			OnCharacterAdded(player, character)
		end)
		
		if player.Character and player.Character:IsDescendantOf(workspace) and player:FindFirstChild("Humanoid") and player.Humanoid.Health > 0 then
			OnCharacterAdded(player, player.Character)
		end
	end
	
	game.Players.PlayerAdded:Connect(function(player)
		OnPlayerAdded(player)
	end)
	for _, player in pairs(game.Players:GetPlayers()) do
		OnPlayerAdded(player)
	end
end

function Initialize()
	SetupPlayerEliminatedEvent()
end
Initialize()


return CommonUtils
