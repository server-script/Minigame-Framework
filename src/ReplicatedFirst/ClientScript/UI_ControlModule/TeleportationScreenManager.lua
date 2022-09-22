local teleportationScreenManager = {}

-- SERVICES --
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local starterGui = game:GetService("StarterGui")

-- MODULES --
local commonUtils = require(game.ReplicatedStorage.Utils.CommonUtils)
local mathUtils = require(game.ReplicatedStorage.Utils.MathUtils)

-- VARIABLES --
--/Settings
local FADE_TWEEN = TweenInfo.new(.2)
local BLACK_SCREEN_MIN_DURATION = .4
local PLAYER_GAMEMODE_ATTRIBUTE = "PlayerGamemode"

--/Enums
local playerGamemodeType = {
	Hub = "Hub",
	Transitioning = "Transitioning",
	Minigames = "Minigames"
}

--/Remotes
local teleportRemotes = game.ReplicatedStorage.Remotes.TeleportationManager
local requestTeleportRemote = teleportRemotes.RequestTeleport

local minigamesFrameworkRemotes = game.ReplicatedStorage.Remotes.MinigamesFramework
local joinMinigamesRemote = minigamesFrameworkRemotes.JoinMinigames
local leaveMinigamesRemote = minigamesFrameworkRemotes.LeaveMinigames

--/References
local localPlayer = game.Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
local mainUI = playerGui.MainUI
local teleportationScreen = mainUI.TeleportationScreen
local checker = teleportationScreen.Checker.Texture
local travelingLabel = teleportationScreen.TravelingLabel
local targetLabel = teleportationScreen.TargetLabel
local teleportationPoints = workspace:WaitForChild("Hub"):WaitForChild("TeleportPoints")



-- PUBLIC METHODS --
function teleportationScreenManager.ShowScreen(teleportText)
	teleportationScreen.Active = true

	starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	
	targetLabel.Text = teleportText
	tweenService:Create(checker, FADE_TWEEN, {ImageTransparency = 0}):Play()
	tweenService:Create(travelingLabel, FADE_TWEEN, {TextTransparency = 0}):Play()
	tweenService:Create(targetLabel, FADE_TWEEN, {TextTransparency = 0}):Play()
	local appearTween = tweenService:Create(teleportationScreen, FADE_TWEEN, {BackgroundTransparency = 0})
	appearTween:Play()
	appearTween.Completed:Wait()
end

function teleportationScreenManager.HideScreen(functionStartTime)
	local timeLeft = BLACK_SCREEN_MIN_DURATION - (time() - functionStartTime)
	if timeLeft > 0 then
		task.wait(timeLeft)
	end

	starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	
	tweenService:Create(checker, FADE_TWEEN, {ImageTransparency = 1}):Play()
	tweenService:Create(travelingLabel, FADE_TWEEN, {TextTransparency = 1}):Play()
	tweenService:Create(targetLabel, FADE_TWEEN, {TextTransparency = 1}):Play()
	local disappearTween = tweenService:Create(teleportationScreen, FADE_TWEEN, {BackgroundTransparency = 1})
	disappearTween:Play()
	disappearTween.Completed:Wait()
	teleportationScreen.Active = false
end

function teleportationScreenManager.TeleportToMinigames()
	teleportationScreenManager.ShowScreen("Minigames")
	local startTime = time()
	joinMinigamesRemote:InvokeServer()
	teleportationScreenManager.HideScreen(startTime)
end

function teleportationScreenManager.TeleportToHub()
	teleportationScreenManager.ShowScreen("Hub")
	local startTime = time()
	leaveMinigamesRemote:InvokeServer()
	teleportationScreenManager.HideScreen(startTime)
end

function teleportationScreenManager.RequestTeleport(teleportName)
	local playerGamemode = localPlayer:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE)
	local teleportReference = teleportationPoints:FindFirstChild(teleportName)
	local rootPart = commonUtils.GetPlayerRootPart(localPlayer)
	local humanoid = commonUtils.GetPlayerHumanoid(localPlayer)
	
	if playerGamemode ~= playerGamemodeType.Hub or not teleportReference or not rootPart or not humanoid or humanoid.Health <= 0 then return end

	local sideButtonsManager = require(script.Parent.SideButtonsManager)
	sideButtonsManager.SetButtonsVisibility(false)
	teleportationScreenManager.ShowScreen("Leaderboard")
	local hideStartTime = time()
	requestTeleportRemote:InvokeServer(teleportName)
	sideButtonsManager.SetButtonsVisibility(true)
	teleportationScreenManager.HideScreen(hideStartTime)
end

-- INITIALIZE --
function Initialize()
	--/Update the checker background
	runService.RenderStepped:Connect(function()
		local checkerOffset = mathUtils.Repeat(time()*50, 100)-50
		checker.Position = UDim2.new(.5,  checkerOffset, .5, checkerOffset)
	end)
end
Initialize()

return teleportationScreenManager
