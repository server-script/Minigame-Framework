--[[
	Goals for this module:
	
	-/ Open/Close tabs
	when opening/closing tabs, it should just make the MinigameUI frame invisible
	
	-/ Adaption
	the minigame ui frame should constantly be adapting to whatever the minigame coordinator's state is
	eg. if the intermission is on, the intermission ui should be visible
	
	-/ Activations
	pretty sure the only activation that needs to handled is the Leave Minigame(back to hub) button
	
	
--]]


local MinigameManager = {}

-- SERVICES --
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local httpService = game:GetService("HttpService")

-- REQUIRES --
local controlModule
local clientMinigamesCoordinator = require(game.ReplicatedFirst.ClientScript.ClientMinigamesCoordinator)
local teleportScreenManager = require(game.ReplicatedFirst.ClientScript.UI_ControlModule.TeleportationScreenManager)

-- VARIABLES --
--/UI References
local localPlayer = game.Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local mainUI = playerGui:WaitForChild("MainUI")
local minigameFrame = mainUI.MinigameUI
local minigameInfoDisplay = minigameFrame.GameInfoDisplay
local minigameDescriptionDisplayLabel = minigameInfoDisplay.DescriptionFrame.Description
local minigameTitleDisplayLabel = minigameInfoDisplay.Title
local leaveMinigamesButton = minigameFrame.ReturnToLobby.Button

--/Game References
local activeMinigameFolder = workspace.ActiveMinigame
local replicatedMinigamesFolder = game.ReplicatedStorage.Minigames

--/Events&Functions
local remotes = game.ReplicatedStorage.Remotes

local minigamesRemotes = remotes.MinigamesFramework

local leaveMinigamesEvent = minigamesRemotes:WaitForChild("LeaveMinigames")

--/Holders
local updateConnectionsToBeErasedOnStatusChanged = {}

--/Constants

--/Enums
local playerGamemodeType = {
	Hub = "Hub",
	Transitioning = "Transitioning",
	Minigames = "Minigames"
}

local minigameStatusDescriptions = {
	WaitingForPlayers = "WAITING FOR MORE PLAYERS TO START",
	StartTimer = "THE NEXT MINIGAME WILL BEGIN SHORTLY",
	Playing = "",
	Intermission = "THE NEXT MINIGAME WILL BEGIN SHORTLY"
}

local minigameTimerAttributeNames = {
	WaitingForPlayers = nil,
	StartTimer = "StartTimer",
	Playing = "MinigameTimer", --/will never be used, so ignore this
	Intermission = "IntermissionTimer",
}

-- PUBLIC METHODS --
function MinigameManager.SetControlModule(module)
	controlModule = module
end

--/OPEN TAB WILL ENABLE ALL MINIGAME UI
function MinigameManager.OpenTab()
	minigameFrame.Visible = true
end

--/OPEN TAB WILL DISABLE ALL MINIGAME UI
function MinigameManager.CloseTab()
	minigameFrame.Visible = false
end

-- PRIVATE FUNCTIONS --

--/Useful Functions
function ClearUpdateConnections()
	for connectionName, connection in pairs(updateConnectionsToBeErasedOnStatusChanged) do
		if connection ~= nil then
			--warn("disconnecting:", connectionName, connection)
			connection:Disconnect()
			updateConnectionsToBeErasedOnStatusChanged[connectionName] = nil
		end
	end
end

--/UI Event Handling
function MinigameStatusUpdated()
	local currentMinigameStatus = activeMinigameFolder:GetAttribute("MinigameStatus")
	if not currentMinigameStatus then
		return
	end
	
	--/Get or wait for minimum players to load
	if activeMinigameFolder:GetAttribute("MinimumPlayers") == nil then
		activeMinigameFolder:GetAttributeChangedSignal("MinimumPlayers"):Wait()
	end
	
	--/Make info display visibility dependant on minigame status
	minigameInfoDisplay.Visible = currentMinigameStatus ~= "Playing"
	
	--/Show minigame status as the title of the display
	if minigameStatusDescriptions[currentMinigameStatus] then
		minigameTitleDisplayLabel.Text = minigameStatusDescriptions[currentMinigameStatus]
	end
	
	--/Get accurate duration according to attributes correlating to currentMinigameStatus
	local attributeTimerName = minigameTimerAttributeNames[currentMinigameStatus]
	local duration

	if attributeTimerName then
		duration = activeMinigameFolder:GetAttribute(attributeTimerName.."Duration")

		if not duration then
			--print("NO DURATION FOR STATUS:", attributeTimerName.."Duration")
		end

	end
	
	--/Get start time for timer
	local startTime = workspace:GetServerTimeNow()
	
	--/If there is a valid duration, then make a timer
	if duration then
		ClearUpdateConnections()

		local lastUpdate = 0
		updateConnectionsToBeErasedOnStatusChanged["timerUpdateConnection"..currentMinigameStatus] = runService.Stepped:Connect(function()
			if math.ceil(duration - (workspace:GetServerTimeNow() - startTime)) ~= lastUpdate then
				minigameDescriptionDisplayLabel.Text = math.ceil(duration - (workspace:GetServerTimeNow() - startTime))
				lastUpdate = math.ceil(duration - (workspace:GetServerTimeNow() - startTime))
			end
			
			--/Clear update connections if timer runs out
			if workspace:GetServerTimeNow() - startTime >= duration then
				ClearUpdateConnections()
				--timerUpdateConnection:Disconnect()
			end
		end)
	else
		--warn("missing duration")
	end

	--/If the status is waiting for players, and minimumplayers att is available, then make a player updating connection
	if activeMinigameFolder:GetAttribute("MinigameStatus") == "WaitingForPlayers" then
		
		--/Clear previous connections
		ClearUpdateConnections()

		local playerCountStartTime = workspace:GetServerTimeNow()
		local lastUpdate = 0
		updateConnectionsToBeErasedOnStatusChanged["playerCountUpdateConnection"..currentMinigameStatus] = runService.Stepped:Connect(function()
			local activePlayers = #clientMinigamesCoordinator.GetPlayersInMinigame()
			local minimumPlayers = activeMinigameFolder:GetAttribute("MinimumPlayers")

			minigameDescriptionDisplayLabel.Text = activePlayers.."/"..minimumPlayers
			
			--/Clear update connections if enough players are reached
			if activePlayers >= minimumPlayers then
				ClearUpdateConnections()
			end
		end)
		
	end
end

function LeaveMinigameButtonActivated()
	teleportScreenManager.TeleportToHub()
end

function PlayerGamemodeChanged(newGamemode)
	if not controlModule then
		return
	end
	
	if newGamemode == playerGamemodeType.Minigames then
		controlModule.OpenTab(script.Name)
	elseif newGamemode == playerGamemodeType.Hub then
		controlModule.CloseTab(script.Name)
	end
end

-- INITIALIZE --
function Initialize()
	
	--/Initialize UI
	minigameFrame.Visible = false
	
	--/Connect open/close to player attributes
	localPlayer:GetAttributeChangedSignal("PlayerGamemode"):Connect(function()
		PlayerGamemodeChanged(localPlayer:GetAttribute("PlayerGamemode"))
	end)
	
	--/Connect active game mode changing
	activeMinigameFolder:GetAttributeChangedSignal("")
	
	--/Connect leave button
	leaveMinigamesButton.Activated:Connect(LeaveMinigameButtonActivated)
	
	--/Connect minigame changing
	activeMinigameFolder:GetAttributeChangedSignal("MinigameStatus"):Connect(function()
		MinigameStatusUpdated()
	end)
	
	MinigameStatusUpdated()
	
end
Initialize()

-- DEBUGGING --
--local oldTime = tick()
--runService.Heartbeat:Connect(function()
--	if tick() - oldTime >= 1 then
--		oldTime = tick()
--		warn(updateConnectionsToBeErasedOnStatusChanged)
--	end
--end)

return MinigameManager
