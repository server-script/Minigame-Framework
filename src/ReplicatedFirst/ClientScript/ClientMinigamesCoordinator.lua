local clientMinigamesCoordinator = {}

-- SERVICES --
local runService = game:GetService("RunService")
local minigamesAPI = require(game.ReplicatedStorage.SharedModules.MinigamesAPI)

-- VARIABLES --
--/Settings
local PLAYER_GAMEMODE_ATTRIBUTE = "PlayerGamemode"
local MINIGAME_STATUS_ATTRIBUTE = "MinigameStatus"

local PLAYERS_REQUIRED_ATTRIBUTE = "PlayersRequired"
local MINIGAME_MAX_DURATION_ATTRIBUTE = "MinigameDuration"
local ACTIVE_MINIGAME_ATTRIBUTE = "ActiveMinigame"

local LAST_MINIGAME_END_TYPE_ATTRIBUTE =  "LastMinigameEndType"

--/Enums
local playerGamemodeType = {
	Hub = "Hub",
	Transitioning = "Transitioning",
	Minigames = "Minigames"
}

local minigameStatusType = {
	WaitingForPlayers = "WaitingForPlayers",
	StartTimer = "StartTimer",
	Playing = "Playing",
	Intermission = "Intermission"
}

--/References
local localPlayer = game.Players.LocalPlayer
local localScripts = localPlayer.PlayerScripts
local sharedMinigamesFolder = game.ReplicatedStorage.Minigames
local activeMinigameFolder = workspace:WaitForChild("ActiveMinigame")
local loadedMinigameClientScripts

--/Holders
local playerTrackers = {}
local playerGamemodeMemory = {}

-- PUBLIC FUNCTIONS --
function clientMinigamesCoordinator.GetPlayersInMinigame()
	local playersInMinigame = {}
	for _, player in pairs(game.Players:GetPlayers()) do
		if player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE) == playerGamemodeType.Minigames then
			table.insert(playersInMinigame, player)
		end
	end
	return playersInMinigame
end

-- PRIVATE FUNCTIONS --
function CreateClientScripts()
	local loadedMinigameName = activeMinigameFolder:GetAttribute(ACTIVE_MINIGAME_ATTRIBUTE)
	local minigameToLoad = sharedMinigamesFolder:FindFirstChild(loadedMinigameName)
	
	for _, clientScript in pairs(minigameToLoad.PlayerScripts:GetChildren()) do
		local newScript = clientScript:Clone()
		newScript.Parent = loadedMinigameClientScripts
	end
end

function CallClientModulesFunction(functionName, waitForCompleted, ...)
	local endsRequired = 0
	local endsMet = 0
	
	for _, clientScript in pairs(loadedMinigameClientScripts:GetChildren()) do
		if clientScript:IsA("ModuleScript")  then
			endsRequired += 1
			local args = {...}
			task.spawn(function()
				local loadedScript = require(clientScript)
				if loadedScript[functionName] then
					loadedScript[functionName](unpack(args))
				end
				endsMet += 1
			end)
		end
	end
	
	if waitForCompleted then
		repeat runService.Stepped:Wait() until endsMet >= endsRequired
	end
end

function OnLoadedMinigameChanged()
	local loadedMinigameName = activeMinigameFolder:GetAttribute(ACTIVE_MINIGAME_ATTRIBUTE)
	local playerGamemode = localPlayer:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE)
	
	if loadedMinigameName and playerGamemode == playerGamemodeType.Minigames then
		CreateClientScripts()
		CallClientModulesFunction("OnMinigameLoaded", false, minigamesAPI, clientMinigamesCoordinator.GetPlayersInMinigame())
	elseif not loadedMinigameName and playerGamemode == playerGamemodeType.Minigames then
		local gameEndType = activeMinigameFolder:GetAttribute(LAST_MINIGAME_END_TYPE_ATTRIBUTE)
		
		CallClientModulesFunction("OnMinigameEnded", true, gameEndType)
		runService.RenderStepped:Wait()
		for _, clientScript in pairs(loadedMinigameClientScripts:GetChildren()) do
			clientScript:Destroy()
		end
	end
end

function OnPlayerAddedToMinigames(player)
	if activeMinigameFolder:GetAttribute(MINIGAME_STATUS_ATTRIBUTE) == minigameStatusType.Playing then
		if player == localPlayer then
			CreateClientScripts()
		end
		
		CallClientModulesFunction("OnPlayerJoinedMinigame", false, player)
	end
end

function OnPlayerRemovedFromMinigames(player)
	if activeMinigameFolder:GetAttribute(MINIGAME_STATUS_ATTRIBUTE) == minigameStatusType.Playing then
		if player ~= localPlayer then
			CallClientModulesFunction("OnPlayerLeavingMinigame", false, player)
		else
			CallClientModulesFunction("OnPlayerLeavingMinigame", true, player)
			runService.RenderStepped:Wait()
			for _, clientScript in pairs(loadedMinigameClientScripts:GetChildren()) do
				clientScript:Destroy()
			end
		end
	end
end

function OnPlayerAdded(player)
	if playerTrackers[player] then
		playerTrackers[player]:Disconnect()
	end
	
	playerGamemodeMemory[player] = player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE)
	
	playerTrackers[player] = player:GetAttributeChangedSignal(PLAYER_GAMEMODE_ATTRIBUTE):Connect(function()
		local playerGamemode = player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE)
		
		
		if playerGamemodeMemory[player] == playerGamemodeType.Hub and playerGamemode == playerGamemodeType.Minigames then
			playerGamemodeMemory[player] = playerGamemode
			OnPlayerAddedToMinigames(player)
		elseif playerGamemodeMemory[player] == playerGamemodeType.Minigames and playerGamemode == playerGamemodeType.Hub then
			playerGamemodeMemory[player] = playerGamemode
			OnPlayerRemovedFromMinigames(player)
		end
	end)
end

function OnPlayerLeaving(player)
	if playerTrackers[player] then
		playerTrackers[player]:Disconnect()
		playerTrackers[player] = nil
	end
	playerGamemodeMemory[player] = nil
	
	if player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE) == playerGamemodeType.Minigames then
		OnPlayerRemovedFromMinigames(player)
	end
end

-- INITIALIZE --
function Initialize()
	loadedMinigameClientScripts = Instance.new("Folder")
	loadedMinigameClientScripts.Name = "LoadedMinigameClientScripts"
	loadedMinigameClientScripts.Parent = localScripts
	
	
	game.Players.PlayerAdded:Connect(OnPlayerAdded)
	for _, player in pairs(game.Players:GetPlayers()) do
		OnPlayerAdded(player)
	end
	
	game.Players.PlayerRemoving:Connect(OnPlayerLeaving)
	

	activeMinigameFolder:GetAttributeChangedSignal(ACTIVE_MINIGAME_ATTRIBUTE):Connect(OnLoadedMinigameChanged)
end
Initialize()

return clientMinigamesCoordinator
