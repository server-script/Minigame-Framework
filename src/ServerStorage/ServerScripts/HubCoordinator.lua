local hubCoordinator = {}

-- SERVICES --
local runService = game:GetService("RunService")

-- MODULES --
local minigamesCoordinator = require(game.ServerStorage.ServerScripts.MinigamesCoordinator)
local mathUtils = require(game.ReplicatedStorage.Utils.MathUtils)

-- VARIABLES --
--/Settings
local PLAYER_GAMEMODE_ATTRIBUTE = "PlayerGamemode"

--/References
--local lobbyTeleportObjectValue = script:WaitForChild("LobbyTeleportPart")

--/Enums
local playerGamemodeType = {
	Hub = "Hub",
	Transitioning = "Transitioning",
	Minigames = "Minigames"
}

--/Remotes
local minigamesFrameworkRemotes = game.ReplicatedStorage.Remotes.MinigamesFramework
local leaveMinigamesRemote = minigamesFrameworkRemotes.LeaveMinigames

--/Holders
local hubFolder = workspace.Hub
local spawnsFolder = hubFolder.Spawns
local lastHubSpawnUsed = 0

-- PUBLIC METHODS --
function hubCoordinator.MovePlayerToHub(player)
	if player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE) == playerGamemodeType.Minigames then
		minigamesCoordinator.RemovePlayerFromMinigames(player)
	end
	
	runService.Stepped:Wait()
	player:SetAttribute(PLAYER_GAMEMODE_ATTRIBUTE, playerGamemodeType.Hub)
	player:LoadCharacter()
end

-- PRIVATE FUNCTIONS --
function SpawnPlayerInHub(player)
	lastHubSpawnUsed += 1
	local allSpawners = spawnsFolder:GetChildren()
	local spawner = allSpawners[mathUtils.Repeat1Up(lastHubSpawnUsed, #allSpawners)]
	local humanoid = player.Character:WaitForChild("Humanoid")
	local rootPart = player.Character:WaitForChild("HumanoidRootPart")
	repeat task.wait() until rootPart:IsDescendantOf(workspace)
	
	rootPart:SetNetworkOwner()
	player.Character:SetPrimaryPartCFrame(CFrame.new(spawner.Position + Vector3.new(0, humanoid.HipHeight + rootPart.Size.Y/2, 0)))
	rootPart:SetNetworkOwner(player)
end

function OnCharacterAdded(player)
	if player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE) == playerGamemodeType.Hub then
		SpawnPlayerInHub()
	end
end

function OnPlayerAdded(player)
	player:SetAttribute(PLAYER_GAMEMODE_ATTRIBUTE, playerGamemodeType.Hub)
	
	player.CharacterAdded:Connect(function()
		SpawnPlayerInHub(player)
	end)
	
	if player.Character and player.Character:IsDescendantOf(workspace) then
		SpawnPlayerInHub(player)
	end
end

function OnPortalCollided(player)
	minigamesCoordinator.MovePlayerToMinigames(player)
end

-- INITIALIZE --
function Initialize()
	--/Initialize all player's gamemode status
	game.Players.PlayerAdded:Connect(OnPlayerAdded)
	for _, player in pairs(game.Players:GetPlayers()) do
		task.spawn(OnPlayerAdded, player)
	end
	
	leaveMinigamesRemote.OnServerInvoke = hubCoordinator.MovePlayerToHub
	
	--/Lobby teleport
	--if not lobbyTeleportObjectValue.Value then
	--	warn("Lobby portal not set up correctly")
	--	return
	--end
	
	--lobbyTeleportObjectValue.Value.Touched:Connect(function(part)
	--	local player = game.Players:GetPlayerFromCharacter(part.Parent)
	--	if not player then return end
		
	--	OnPortalCollided(player)
	--end)
end
Initialize()

return hubCoordinator
