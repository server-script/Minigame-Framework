local minigamesCoordinator = {}

-- SERVICES --
local runService = game:GetService("RunService")

-- MODULES --
local datastoreManager = require(game.ServerStorage.ServerScripts.DatastoreManager)
local mathUtils = require(game.ReplicatedStorage.Utils.MathUtils)
local minigamesAPI = require(game.ReplicatedStorage.SharedModules.MinigamesAPI)
local commonUtils = require(game.ReplicatedStorage.Utils.CommonUtils)
local podiumManager = require(game.ServerStorage.ServerScripts.PodiumManager)

-- VARIABLES --
--/Settings
local PLAYER_GAMEMODE_ATTRIBUTE = "PlayerGamemode"
local MINIGAME_STATUS_ATTRIBUTE = "MinigameStatus"
local PLAYERS_REQUIRED_ATTRIBUTE = "PlayersRequirement"

local MINIGAME_MAX_DURATION_ATTRIBUTE = "MinigameDuration"
local ACTIVE_MINIGAME_ATTRIBUTE = "ActiveMinigame"

local MINIGAME_TIMER_BEGIN_ATTRIBUTE = "MinigameTimerBegin"
local MINIGAME_TIMER_DURATION_ATTRIBUTE = "MinigameTimerDuration"

local START_TIMER_BEGIN_ATTRIBUTE = "StartTimerBegin"
local START_TIMER_DURATION_ATTRIBUTE = "StartTimerDuration"

local INTERMISSION_TIMER_BEGIN_ATTRIBUTE = "IntermissionTimerBegin"
local INTERMISSION_TIMER_DURATION_ATTRIBUTE = "IntermissionTimerDuration"

local LAST_MINIGAME_END_TYPE_ATTRIBUTE =  "LastMinigameEndType"

local MINIMUM_PLAYERS_ATTRIBUTE = "MinimumPlayers"

local START_TIMER_DURATION = 3
local INTERMISSION_TIMER_DURATION = 12
local MINIGAMES_FORCE_SKIP_LENGTH = 3

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


--/Remotes
local minigamesFrameworkRemotes = game.ReplicatedStorage.Remotes.MinigamesFramework
local joinMinigamesRemote = minigamesFrameworkRemotes.JoinMinigames

--/References
local serverMinigamesFolder = game.ServerStorage.Minigames
local sharedMinigamesFolder = game.ReplicatedStorage.Minigames
local activeMinigameFolder = workspace.ActiveMinigame
local loadedMinigameServerScripts = game.ServerScriptService.LoadedMinigameServerScripts

local lobbyFolder = workspace.Lobby
local lobbySpawns = lobbyFolder.Spawns
local hubFolder = workspace.Hub
local hubSpawns = hubFolder.Spawns

--/Holders
local minimumPlayersRequired = 100
local activeMinimumPlayersOverride

local lastMinigames = {}
local startTimerUpdate
local minigameTimerUpdate
local intermissionTimerUpdate

local minigamesPool
local loadedMinigame

-- PUBLIC METHODS --
function minigamesCoordinator.MovePlayerToMinigames(player)
	if not (player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE) == playerGamemodeType.Minigames) then
		
		--/Set game mode attribute
		player:SetAttribute(PLAYER_GAMEMODE_ATTRIBUTE, playerGamemodeType.Minigames)
		
		--/Reload character before teleporting
		local character = player.Character
		local reloadTime = time()
		player:LoadCharacter()
		
		--/Wait for new character without causing memory leaks or infinite waits
		local repeatTimeOut = 2
		repeat 
			task.wait()
			if time() - reloadTime > repeatTimeOut then
				break
			end
			
		until player.Character ~= character
		
		--/Teleport player to lobby before sending joined event
		MoveCharacterToRandomSpawn(player, lobbySpawns)
		
		OnPlayerAddedToMinigames(player)
	end
end

function minigamesCoordinator.RemovePlayerFromMinigames(player)
	if player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE) == playerGamemodeType.Minigames then
		OnPlayerRemovedFromMinigames(player)
	end
end

function minigamesCoordinator.GetPlayersInMinigame()
	local playersInMinigame = {}
	for _, player in pairs(game.Players:GetPlayers()) do
		if player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE) == playerGamemodeType.Minigames then
			table.insert(playersInMinigame, player)
		end
	end
	return playersInMinigame
end

function minigamesCoordinator.ForceEndMinigame()
	EndMinigame("Requested")
end

function minigamesCoordinator.AdjustMinimumPlayersRequired(newAmount)
	activeMinimumPlayersOverride = newAmount
	
	task.spawn(function()
		if #minigamesCoordinator.GetPlayersInMinigame() < (activeMinimumPlayersOverride or loadedMinigame:GetAttribute(PLAYERS_REQUIRED_ATTRIBUTE)) then
			EndMinigame("NotEnoughPlayers")
		end
	end)
end

function minigamesCoordinator.StoreActiveMinigamePointsAndCoins(player, points, coins)
	local currentActivePoints = player:GetAttribute("ActiveMinigamePoints") or 0
	player:SetAttribute("ActiveMinigamePoints", currentActivePoints + points)
	
	local currentActiveCoins = player:GetAttribute("ActiveMinigameCoins") or 0
	player:SetAttribute("ActiveMinigameCoins", currentActiveCoins + coins)
end

function minigamesCoordinator.SetMinigamesPool(newPool)
	minigamesPool = newPool
end

-- PRIVATE FUNCTIONS --
function CallServerModulesFunction(functionName, waitForCompleted, ...)
	local endsRequired = 0
	local endsMet = 0

	for _, clientScript in pairs(loadedMinigameServerScripts:GetChildren()) do
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

function PlayIntermission()	
	--/Initialize status
	activeMinigameFolder:SetAttribute(MINIGAME_STATUS_ATTRIBUTE, minigameStatusType.Intermission)

	--/Start the timer
	activeMinigameFolder:SetAttribute(INTERMISSION_TIMER_BEGIN_ATTRIBUTE, workspace:GetServerTimeNow())
	activeMinigameFolder:SetAttribute(INTERMISSION_TIMER_DURATION_ATTRIBUTE, INTERMISSION_TIMER_DURATION)

	local intermissionStart = workspace:GetServerTimeNow()
	intermissionTimerUpdate = runService.Stepped:Connect(function()
		
		if workspace:GetServerTimeNow() - intermissionStart >= INTERMISSION_TIMER_DURATION then
			intermissionTimerUpdate:Disconnect()
			if #minigamesCoordinator.GetPlayersInMinigame() >= minimumPlayersRequired then
				StartNextMinigame()
			else
				SetWaitingForPlayersAttributes()
			end
		end
	end)
end

function GetMinigameWinners()
	
	local playerPointsHolder = {}
	
	--/Insert players into points holder
	for _, player in pairs(game.Players:GetPlayers()) do
		--/Only players that are in the current minigame
		if player:GetAttribute("PlayerGamemode") ~= "Minigames" then
			continue
		end
		
		if player:GetAttribute("ActiveMinigamePoints") == nil then
			continue
		end
		
		table.insert(playerPointsHolder, {
			player = player, 
			points = player:GetAttribute("ActiveMinigamePoints") or 0
		})
	end
	
	--/Sort winners table
	table.sort(playerPointsHolder, function(a,b)
		return a.points > b.points
	end)
	
	--/Get top three players
	local topThreeWinners = {}
	
	for i = 1, 3 do
		if playerPointsHolder[i] then
			table.insert(topThreeWinners, playerPointsHolder[i].player)
		end
	end
	
	return topThreeWinners
end

function EndMinigame(minigameEndType)
	--/Cleanup memory
	activeMinigameFolder:SetAttribute(LAST_MINIGAME_END_TYPE_ATTRIBUTE, minigameEndType)
	activeMinigameFolder:SetAttribute(MINIGAME_TIMER_BEGIN_ATTRIBUTE)
	activeMinigameFolder:SetAttribute(MINIGAME_TIMER_DURATION_ATTRIBUTE)
	activeMinigameFolder:SetAttribute(ACTIVE_MINIGAME_ATTRIBUTE)
	
	--/Move players back to minigames spawns
	for _, player in pairs(game.Players:GetPlayers()) do
		if player:GetAttribute("PlayerGamemode") == "Minigames" then
			MoveCharacterToRandomSpawn(player, lobbySpawns)
		end
	end
	
	--/Display winners on podium
	podiumManager.DisplayWinners(GetMinigameWinners())
	
	--/Cleanup stored active minigame points
	for _, player in pairs(game.Players:GetPlayers()) do
		player:SetAttribute("ActiveMinigamePoints")
		player:SetAttribute("ActiveMinigameCoins")
	end
	
	if minigameTimerUpdate then
		minigameTimerUpdate:Disconnect()
	end
	loadedMinigame = nil
	activeMinimumPlayersOverride = nil

	--/Initialize status
	activeMinigameFolder:SetAttribute(MINIGAME_STATUS_ATTRIBUTE, minigameStatusType.Intermission)
	
	--/Send game ending message
	CallServerModulesFunction("OnMinigameEnded", true, minigameEndType)	
	
	--/Cleanup map and scripts
	runService.Stepped:Wait()
	for _, serverScript in pairs(loadedMinigameServerScripts:GetChildren()) do
		serverScript:Destroy()
	end
	for _, element in pairs(activeMinigameFolder.LoadedMap:GetChildren()) do
		element:Destroy()
	end
	
	--/Start the intermission
	PlayIntermission()
end

function StartNextMinigame()
	--/Cleanup timer
	activeMinigameFolder:SetAttribute(START_TIMER_BEGIN_ATTRIBUTE)
	--activeMinigameFolder:SetAttribute(START_TIMER_DURATION_ATTRIBUTE)
	
	--/Initialize status
	activeMinigameFolder:SetAttribute(MINIGAME_STATUS_ATTRIBUTE, minigameStatusType.Playing)
	
	local minigameToLoad = PickNextMinigame()
	local sharedMinigameToLoad = sharedMinigamesFolder[minigameToLoad.Name]
	loadedMinigame = minigameToLoad
	
	--/Load minigame map
	local mapClone = sharedMinigameToLoad.Map:Clone()
	for _, element in pairs(mapClone:GetChildren()) do
		element.Parent = activeMinigameFolder.LoadedMap
	end

	--/Send message for client to load
	activeMinigameFolder:SetAttribute(ACTIVE_MINIGAME_ATTRIBUTE, sharedMinigameToLoad.Name)
	
	--/Load ServerScripts
	for _, serverScript in pairs(minigameToLoad.ServerScripts:GetChildren()) do
		local newScript = serverScript:Clone()
		newScript.Parent = loadedMinigameServerScripts
	end
	
	CallServerModulesFunction("OnMinigameLoaded", false, minigamesAPI, minigamesCoordinator.GetPlayersInMinigame())
	
	--/Start the timer
	local minigameTimerDuration = sharedMinigameToLoad:GetAttribute(MINIGAME_MAX_DURATION_ATTRIBUTE)
	minigameTimerDuration = minigameTimerDuration and math.min(minigameTimerDuration, 600) or 600
	
	activeMinigameFolder:SetAttribute(MINIGAME_TIMER_BEGIN_ATTRIBUTE, workspace:GetServerTimeNow())
	activeMinigameFolder:SetAttribute(MINIGAME_TIMER_DURATION_ATTRIBUTE, minigameTimerDuration)
	
	local minigameStart = workspace:GetServerTimeNow()
	
	minigameTimerUpdate = runService.Stepped:Connect(function()
		
		if workspace:GetServerTimeNow() - minigameStart >= minigameTimerDuration then
			EndMinigame("TimerEnd")
		end
	end)
	
	--/Clear old podium winners
	podiumManager.ClearWinners()
	
end

function PickNextMinigame()
	--/Wait for the minigames pool
	if not minigamesPool then
		repeat task.wait() until minigamesPool
	end
	
	--/Find all the possible minigames
	local possibleMinigames = {}
	for _, minigame in pairs(minigamesPool) do
		--print(minigame:GetAttributes())
		if minigame:GetAttribute(PLAYERS_REQUIRED_ATTRIBUTE) <= #minigamesCoordinator.GetPlayersInMinigame() then
			table.insert(possibleMinigames, minigame)
		end
	end
	
	--/Remove the last games played to grant variety
	for _, minigame in pairs(lastMinigames) do
		table.remove(possibleMinigames, table.find(possibleMinigames, minigame))
	end
	if #possibleMinigames < 1 then
		table.insert(possibleMinigames, lastMinigames[1])
		table.remove(lastMinigames, 1)
	end
	
	--/Catalogue each game's plays
	local minigamePlays = {}
	for _, minigame in pairs(possibleMinigames) do
		minigamePlays[minigame] = 0
	end
	
	for _, player in pairs(minigamesCoordinator.GetPlayersInMinigame()) do
		if not datastoreManager:PlayerDataIsLoaded(player) then continue end
		local playerData = datastoreManager[player].Data
		if not playerData.minigamePlays then continue end
		
		for _, minigame in pairs(possibleMinigames) do
			if playerData.minigamePlays[minigame.Name] then
				minigamePlays[minigame] += playerData.minigamePlays[minigame.Name]
			end
		end
	end
	
	--/Find the most played game
	local mostPlays = 0
	for	minigame, plays in pairs(minigamePlays) do
		if plays > mostPlays then
			mostPlays = plays
		end
	end
	mostPlays += 1
	
	--/Create a weight table from the inversed plays
	local minigamesWeightTable = {}
	for minigame, plays in pairs(minigamePlays) do
		minigamesWeightTable[minigame] = mostPlays - plays
	end
	
	--/Pick the minigame from the table
	local minigamePicked = mathUtils.RandomFromWeightTable(minigamesWeightTable)
	
	--/Save the minigame picked on players and server
	table.insert(lastMinigames, minigamePicked)
	if #lastMinigames > MINIGAMES_FORCE_SKIP_LENGTH then
		table.remove(lastMinigames, 1)
	end
	
	for _, player in pairs(minigamesCoordinator.GetPlayersInMinigame()) do
		if not datastoreManager:PlayerDataIsLoaded(player) then continue end
		local playerData = datastoreManager[player].Data
		if not playerData.minigamePlays then playerData.minigamePlays = {} end
		
		if playerData.minigamePlays[minigamePicked.Name] then
			playerData.minigamePlays[minigamePicked.Name] += 1
		else
			playerData.minigamePlays[minigamePicked.Name] = 1
		end
	end
	
	
	return minigamePicked
end

function EnableStartTimer()
	activeMinigameFolder:SetAttribute(MINIGAME_STATUS_ATTRIBUTE, minigameStatusType.StartTimer)
	activeMinigameFolder:SetAttribute(START_TIMER_BEGIN_ATTRIBUTE, workspace:GetServerTimeNow())
	activeMinigameFolder:SetAttribute(START_TIMER_DURATION_ATTRIBUTE, START_TIMER_DURATION)
	
	local timerStart = workspace:GetServerTimeNow()
	startTimerUpdate = runService.Stepped:Connect(function()
		
		if workspace:GetServerTimeNow() - timerStart >= START_TIMER_DURATION then
			startTimerUpdate:Disconnect()
			StartNextMinigame()
		end
	end)
end

function DisableStartTimer()
	activeMinigameFolder:SetAttribute(START_TIMER_BEGIN_ATTRIBUTE)
	--activeMinigameFolder:SetAttribute(START_TIMER_DURATION_ATTRIBUTE)
	SetWaitingForPlayersAttributes()
	if startTimerUpdate then
		startTimerUpdate:Disconnect()
	end
end

function CheckForTimerStart()
	if activeMinigameFolder:GetAttribute(MINIGAME_STATUS_ATTRIBUTE) == minigameStatusType.WaitingForPlayers then
		if #minigamesCoordinator.GetPlayersInMinigame() >= minimumPlayersRequired then
			EnableStartTimer()
		end
	end
end

function SetWaitingForPlayersAttributes()
	--/Set minigame status attribute
	activeMinigameFolder:SetAttribute(MINIGAME_STATUS_ATTRIBUTE, minigameStatusType.WaitingForPlayers)
	
	--/Set minimum players required attribute
	if loadedMinigame then
		activeMinigameFolder:SetAttribute(MINIMUM_PLAYERS_ATTRIBUTE, activeMinimumPlayersOverride or 
			loadedMinigame:GetAttribute(PLAYERS_REQUIRED_ATTRIBUTE) or 
			minimumPlayersRequired)
	else
		activeMinigameFolder:SetAttribute(MINIMUM_PLAYERS_ATTRIBUTE, activeMinimumPlayersOverride or minimumPlayersRequired)
	end
	
end

function OnPlayerAddedToMinigames(player)
	local minigameStatus = activeMinigameFolder:GetAttribute(MINIGAME_STATUS_ATTRIBUTE)
	
	if minigameStatus == minigameStatusType.WaitingForPlayers then
		CheckForTimerStart()
	elseif minigameStatus == minigameStatusType.Playing then
		--/Send player joined message
		CallServerModulesFunction("OnPlayerJoinedMinigame", false, player)
	end
end

function OnPlayerRemovedFromMinigames(player)
	local minigameStatus = activeMinigameFolder:GetAttribute(MINIGAME_STATUS_ATTRIBUTE)
	
	if minigameStatus == minigameStatusType.StartTimer then
		if #minigamesCoordinator.GetPlayersInMinigame() < minimumPlayersRequired then
			DisableStartTimer()
		end
		
	elseif minigameStatus == minigameStatusType.Playing then
		--/Send player leaving message
		CallServerModulesFunction("OnPlayerLeavingMinigame", false, player)
		
		if #minigamesCoordinator.GetPlayersInMinigame() < (activeMinimumPlayersOverride or loadedMinigame:GetAttribute(PLAYERS_REQUIRED_ATTRIBUTE)) then
			EndMinigame("NotEnoughPlayers")
		end
		
	elseif minigameStatus == minigameStatusType.Intermission then
		if #minigamesCoordinator.GetPlayersInMinigame() < 1 then
			intermissionTimerUpdate:Disconnect()
			SetWaitingForPlayersAttributes()
		end
	end
end

function OnPlayerRemoved(player)
	if player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE) == playerGamemodeType.Minigames then
		OnPlayerRemovedFromMinigames(player)
	end
end

function ReplicateMinigames()
	for _, minigame in pairs(serverMinigamesFolder:GetChildren()) do
		local minigameClone = minigame:Clone()
		minigameClone.ServerScripts:Destroy()
		minigameClone.Parent = sharedMinigamesFolder
	end
end

function CalculateMinimumPlayersRequired()
	if not minigamesPool then
		repeat task.wait() until minigamesPool
	end
	
	for _, minigame in pairs(minigamesPool) do
		if minigame:GetAttribute(PLAYERS_REQUIRED_ATTRIBUTE) < minimumPlayersRequired then
			minimumPlayersRequired = minigame:GetAttribute(PLAYERS_REQUIRED_ATTRIBUTE)
		end
	end
end

function GetRandomSpawn(spawnsFolder)
	local spawns = spawnsFolder:GetChildren()
	local spawnsList = {}
	for _, instance in pairs(spawns) do
		if instance:IsA("BasePart") then
			table.insert(spawnsList, instance)
		end
	end
	local randomIndex = math.random(#spawnsList)

	return spawnsList[randomIndex]
end

function MoveCharacterToRandomSpawn(player, spawnsFolder)
	--/Teleport player to lobby before sending joined event
	local humanoid = commonUtils.WaitPlayerHumanoid(player)

	if humanoid and humanoid.Health > 0 then
		local rootPart = commonUtils.GetPlayerRootPart(player)
		if rootPart then
			local selectedSpawn = GetRandomSpawn(spawnsFolder)
			rootPart.CFrame = selectedSpawn.CFrame + Vector3.new(0, 4, 0)
		end
	end
end

-- INITIALIZE --
function Initialize()
	--/Enable all minigames to let developers test easily
	minigamesCoordinator.SetMinigamesPool(game.ServerStorage.Minigames:GetChildren())
	
	--/Move minigames client elements to replicatedStorage
	ReplicateMinigames()
	CalculateMinimumPlayersRequired()
	
	game.Players.PlayerRemoving:Connect(OnPlayerRemoved)
	joinMinigamesRemote.OnServerInvoke = minigamesCoordinator.MovePlayerToMinigames
	
	SetWaitingForPlayersAttributes()
	CheckForTimerStart()
end
task.spawn(Initialize)

return minigamesCoordinator
