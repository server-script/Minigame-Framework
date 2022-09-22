local minigamesAPI = {}

-- SERVICES --
local runService = game:GetService("RunService")

-- VARIABLES --
--/Settings
local PLAYER_GAMEMODE_ATTRIBUTE = "PlayerGamemode"
local ACTIVE_MINIGAME_ATTRIBUTE = "ActiveMinigame"

local MINIGAME_TIMER_BEGIN_ATTRIBUTE = "MinigameTimerBegin"
local MINIGAME_TIMER_DURATION_ATTRIBUTE = "MinigameTimerDuration"

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
local sharedMinigamesFolder = game.ReplicatedStorage.Minigames
local activeMinigameFolder = workspace:WaitForChild("ActiveMinigame")

-- PUBLIC FUNCTIONS --
function minigamesAPI.GetPlayers()
	local playersInMinigame = {}
	for _, player in pairs(game.Players:GetPlayers()) do
		if player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE) == playerGamemodeType.Minigames then
			table.insert(playersInMinigame, player)
		end
	end
	return playersInMinigame
end

function minigamesAPI.GetMinigamesFolder()
	local loadedMinigameName = activeMinigameFolder:GetAttribute(ACTIVE_MINIGAME_ATTRIBUTE)
	return sharedMinigamesFolder:FindFirstChild(loadedMinigameName)
end

function minigamesAPI.GetLoadedMapFolder()
	return activeMinigameFolder.LoadedMap
end

function minigamesAPI.PlayerIsInMinigame(player)
	return player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE) == playerGamemodeType.Minigames
end

function minigamesAPI.GetRemainingTime()
	local timerStart = activeMinigameFolder:GetAttribute(MINIGAME_TIMER_BEGIN_ATTRIBUTE)
	local timerDuration = activeMinigameFolder:GetAttribute(MINIGAME_TIMER_DURATION_ATTRIBUTE)
	
	return math.max(0, timerDuration - (workspace:GetServerTimeNow() - timerStart))
end

function minigamesAPI.EndMinigame()
	if not runService:IsServer() then 
		error("Attempted to call EndMinigame from client")
	end
	
	local minigamesCoordinator = require(game.ServerStorage.ServerScripts.MinigamesCoordinator)
	minigamesCoordinator.ForceEndMinigame()
end

function minigamesAPI.AdjustMinimumPlayersRequired(newAmount)
	if not runService:IsServer() then 
		error("Attempted to call AdjustMinimumPlayersRequired from client")
	end

	local minigamesCoordinator = require(game.ServerStorage.ServerScripts.MinigamesCoordinator)
	minigamesCoordinator.AdjustMinimumPlayersRequired(newAmount)
end

function minigamesAPI.AwardPointsAndCoins(player, coins, points)
	if not runService:IsServer() then 
		error("Attempted to call AwardPointsAndCoins from client")
	end
	
	coins = math.min(100, coins)
	points = math.min(100, points)
	
	--/Record minigame points
	local minigamesCoordinator = require(game.ServerStorage.ServerScripts.MinigamesCoordinator)
	minigamesCoordinator.StoreActiveMinigamePointsAndCoins(player, points, coins)
	
	local moneyManager = require(game.ServerStorage.ServerScripts.MoneyManager)
	
	task.spawn(function()
		moneyManager:AddFunds(player, "Coins", coins, true)
		moneyManager:AddFunds(player, "Points", points, true)
		warn("Added", coins, "Coins")
		warn("Added", points, "Points")
	end)
end

return minigamesAPI
