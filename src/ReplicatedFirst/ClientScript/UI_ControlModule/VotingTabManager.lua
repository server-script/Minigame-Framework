--[[
	Goals for this module:
	
	-/ Open/Close tabs
	when opening/closing tabs, it should just make the voting tab invisible
	
	-/ Adaption
	the voting frame should be visible during X minigamestatus
	show the winning points and coins on the right side
	
	-/ Activations
	heart button activation (see ClientDeveloperPillarsHandler for example)
	close button
	
	
	
--]]



local VotingTabManager = {}

-- SERVICES --
local players = game:GetService("Players")
local runService = game:GetService("RunService")

-- REQUIRES --
local controlModule
local clientMinigamesCoordinator = require(game.ReplicatedFirst.ClientScript.ClientMinigamesCoordinator)
--local votingManager = require(game.ReplicatedFirst.ClientScript.ClientVotingManager)

-- VARIABLES --
--/Settings
local LIKE_COOLDOWN = 0.5

--/UI References
local localPlayer = game.Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local mainUI = playerGui:WaitForChild("MainUI")
local minigameFrame = mainUI.MinigameUI

local minigameMiddleFrame = minigameFrame.MiddleFrame

local minigameResultsFrame = minigameMiddleFrame.MinigameResults

local mainFrame = minigameResultsFrame.Main
local likeCountFrame = mainFrame.LikeCount
local likeCountLabel = likeCountFrame.Likes
local minigameDescriptionLabel = mainFrame.Desc

local rewardsFrame = minigameResultsFrame.Rewards
local coinRewardLabel = rewardsFrame.Coins.Amount
local pointsRewardLabel = rewardsFrame.Points.Amount
local minigameIcon = mainFrame.MinigameIcon

local heartFrame = minigameResultsFrame.Heart
local heartButton = heartFrame.Button
local likeConfirmedImage = heartFrame.HeartButtonConfirmed
local likeImage = heartFrame.HeartButton

--/Game References
local activeMinigameFolder = workspace.ActiveMinigame
local minigamesFolder = game.ReplicatedStorage.Minigames

--/Events&Functions
local remotes = game.ReplicatedStorage.Remotes

--local votesRemotes = remotes.VotesManager
--local votesUpdatedRemote = votesRemotes.VotesUpdated

--/Holders
local trackedMinigame = nil
local lastLikeChange = time()
local votesCache = {}
local pointsAndCoinsEarnedCache = {points = 0, coins = 0}

--/Constants

--/Enums
local minigameStatusType = {
	WaitingForPlayers = "WaitingForPlayers",
	StartTimer = "StartTimer",
	Playing = "Playing",
	Intermission = "Intermission"
}

local playerGamemodeType = {
	Hub = "Hub",
	Transitioning = "Transitioning",
	Minigames = "Minigames"
}

-- PUBLIC METHODS --
function VotingTabManager.SetControlModule(module)
	controlModule = module
end

--/OPEN TAB WILL ENABLE ALL MINIGAME UI
function VotingTabManager.OpenTab()
	minigameResultsFrame.Visible = true
end

--/OPEN TAB WILL DISABLE ALL MINIGAME UI
function VotingTabManager.CloseTab()
	minigameResultsFrame.Visible = false
end

-- PRIVATE FUNCTIONS --

--/Useful Functions
function UpdateDisplayInfo()
	--/Display points and coins info at the end of the rounds
	
	--print("POINTS AND COINS EARNED THIS MINIGAME:", pointsAndCoinsEarnedCache)
	
	pointsRewardLabel.Text = ("+ ".. pointsAndCoinsEarnedCache.points.. " Points")
	coinRewardLabel.Text = ("+ ".. pointsAndCoinsEarnedCache.coins.. " Coins")
	
	--/Reconcile like button
	ReconcileLikeButton()
	
	--/Reconcile like count
	likeCountLabel.Text = votesCache[trackedMinigame] or 0
	
	--/Update icon id
	local trackedMinigameFolder = minigamesFolder:FindFirstChild(trackedMinigame)
	if not trackedMinigameFolder then
		return
	end
	
	local iconId = trackedMinigameFolder:FindFirstChild("Icon").Texture or 0
	minigameIcon.Image = iconId
	
end

function ReconcileLikeButton()
	likeConfirmedImage.Visible = false --votingManager.votesMemory[trackedMinigame] and true or false
end

function CachePointsAndCoins()
	local pointsEarned = localPlayer:GetAttribute("ActiveMinigamePoints")
	local coinsEarned = localPlayer:GetAttribute("ActiveMinigameCoins")

	pointsAndCoinsEarnedCache.points = pointsEarned or pointsAndCoinsEarnedCache.points
	pointsAndCoinsEarnedCache.coins = coinsEarned or pointsAndCoinsEarnedCache.coins
end

--/UI Event Handling
function MinigameStatusUpdated()
	--/Make sure controlModule is available
	if not controlModule then
		return
	end
	
	--/Handle visibility and info updating according to attribute
	local currentMinigameStatus = activeMinigameFolder:GetAttribute("MinigameStatus")
	
	if currentMinigameStatus == minigameStatusType.Intermission then
		UpdateDisplayInfo()
		
		controlModule.OpenTab(script.Name, true)
	elseif currentMinigameStatus == minigameStatusType.Playing then
		controlModule.CloseTab(script.Name)
	end
end

function HeartButtonActivated()	
	--/Make sure there is a valid minigame to vote on
	if not trackedMinigame then
		return
	end
	
	--/Click debounce
	if time() - lastLikeChange < LIKE_COOLDOWN then return end
	
	--/Tell client vote manager what we want
	local voteChange = 0--votingManager.UpdateVote(trackedMinigame, not (votingManager.votesMemory[trackedMinigame] and true or false))
	
	--/Edit UI accordingly
	likeCountLabel.Text = (tonumber(likeCountLabel.Text) or 0) + voteChange
	
	--/Reconcile like button
	ReconcileLikeButton()
end

-- INITIALIZE --
function Initialize()
	
	--/Initialize UI
	minigameResultsFrame.Visible = false

	--/Connect leave button
	heartButton.Activated:Connect(HeartButtonActivated)
	
	--/Connect minigame changing
	activeMinigameFolder:GetAttributeChangedSignal("MinigameStatus"):Connect(function()
		MinigameStatusUpdated()
	end)
	
	--/Track minigames
	activeMinigameFolder:GetAttributeChangedSignal("ActiveMinigame"):Connect(function()
		local attributeValue = activeMinigameFolder:GetAttribute("ActiveMinigame")
		if attributeValue then
			trackedMinigame = attributeValue
		end
	end)
	
	--/Track minigame votes
	--votesUpdatedRemote.OnClientEvent:Connect(function(newData)
	--	votesCache = newData
	--end)
	
	--/Track minigame earnings
	localPlayer:GetAttributeChangedSignal("ActiveMinigamePoints"):Connect(function()
		CachePointsAndCoins()
	end)
	
	localPlayer:GetAttributeChangedSignal("ActiveMinigameCoins"):Connect(function()
		CachePointsAndCoins()
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

return VotingTabManager
