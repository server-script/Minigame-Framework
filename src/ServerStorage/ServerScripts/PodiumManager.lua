local podiumManager = {}

--[[
>Change active minigames, both initialized and at the end of a minigame match
>Change pillar displayed player and tracked minigames

]]


-- SERVICES --
local runService = game:GetService("RunService")
local physicsService = game:GetService("PhysicsService")

-- MODULES --
local commonUtils = require(game.ReplicatedStorage.Utils.CommonUtils)

-- VARIABLES --
--/Settings
local PODIUM_NAMES = {
	"First",
	"Second",
	"Third"
}

--/References
local lobbyFolder = workspace.Lobby
local minigamePodiums = lobbyFolder.MinigamePodiums
local charactersHolder = minigamePodiums.CharactersHolder

local defaultCharacterModel = game.ReplicatedStorage.Prefabs.Characters.DefaultCharacter

local activeMinigameFolder = workspace.ActiveMinigame

--/Constants
local NON_COLLIDE_CHARACTERS_GROUP_NAME = "NonCollideCharacters"

--/Enums
local minigameStatusType = {
	WaitingForPlayers = "WaitingForPlayers",
	StartTimer = "StartTimer",
	Playing = "Playing",
	Intermission = "Intermission"
}

-- PUBLIC METHODS --
--/Table should look like: {first = player, second = player, third = player}
function podiumManager.DisplayWinners(winnersTable)
	
	--/Get rid of previous if there is any
	podiumManager.ClearWinners()
	
	--/Loop through winners table
	for index, player in pairs(winnersTable) do
		
		--/Make sure podium model is found
		local podiumModel = minigamePodiums:FindFirstChild(PODIUM_NAMES[index])
		if not podiumModel then
			warn("Could not find podiumModel for:", PODIUM_NAMES[index])
			continue
		end
		
		--/Wrap in coroutine because both functions are yielding functions that rely on roblox data
		coroutine.wrap(function()
			--/Display user data
			DisplayUserDataOnPodium(player, podiumModel)
			
			--/Display character on podium
			DisplayCharacterAtPodium(player, podiumModel)
		end)()
		
	end
	
end

function podiumManager.ClearWinners()
	--/Clear user data
	for _, podiumModel in pairs(minigamePodiums:GetChildren()) do
		if podiumModel:IsA("Model") then
			local surfaceUi, playerIconLabel, playerNameLabel = GetUIElements(podiumModel)
			playerNameLabel.Text = ""
			playerIconLabel.Image = ""
		end
	end
	
	--/Clear characters
	charactersHolder:ClearAllChildren()
end

-- PRIVATE FUNCTIONS --
function GetUIElements(podiumModel)
	--/Get ui elements needed
	local surfaceUi = commonUtils.FindFirstChildChain(podiumModel, "CoreParts", "Board", "InfoGui")
	if not surfaceUi then
		warn("Could not find surface gui for podium:", podiumModel)
		return
	end

	local playerIconLabel = surfaceUi:FindFirstChild("PlayerIcon")
	local playerNameLabel = surfaceUi:FindFirstChild("PlayerName")
	if not playerIconLabel or not playerNameLabel then
		warn("Could not find icon or name label")
		return surfaceUi
	end
	
	return surfaceUi, playerIconLabel, playerNameLabel
end

function DisplayUserDataOnPodium(player, podiumModel)
	--/Get ui variables
	local surfaceUi, playerIconLabel, playerNameLabel = GetUIElements(podiumModel)
	
	--/Set player name
	playerNameLabel.Text = player.Name
	
	--/Create default icon id
	local iconId = 0
	
	--/Wrap function in pcall, because this function needs to get data from roblox
	local success, response = pcall(function()
		iconId = game.Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
	end)
	
	playerIconLabel.Image = iconId
end

function DisplayCharacterAtPodium(player, podiumModel)
	--/Create default character
	local newCharacter
	
	--/Wrap function in pcall, because this function needs to get data from roblox
	local success, response = pcall(function()
		newCharacter = game.Players:CreateHumanoidModelFromUserId(player.UserId)
	end)
	
	if not success then
		warn(player, "character could not be loaded. Loading default character")
		
		newCharacter = defaultCharacterModel:Clone()
	end
	
	--/Set up new character
	newCharacter.Parent = charactersHolder
	newCharacter.PrimaryPart.Anchored = true

	local characterCFrame = podiumModel.CoreParts.spawnPart.CFrame + Vector3.new(0, 4, 0) --/TODO: Get accurate player height and place them correctly
	newCharacter:SetPrimaryPartCFrame(characterCFrame)
	
	for _, part in pairs(newCharacter:GetDescendants()) do
		if part:IsA("BasePart") then
			physicsService:SetPartCollisionGroup(part, NON_COLLIDE_CHARACTERS_GROUP_NAME)
		end
	end
end

-- INITIALIZE --
function Initialize()
	podiumManager.ClearWinners()
	
	--/TESTING
	--warn("INITIALIZING PODIUM MANAGER")
	
	--coroutine.wrap(function()
	--	wait(5)
	--	while true do
	--		local testCharacters = {first = game.Players.DEV_Sal}
	--		podiumManager.DisplayWinners(testCharacters)
			
	--		wait(15)
			
	--		podiumManager.ClearWinners()
			
	--		wait(2)
	--	end
	--end)()
	
end
Initialize()

return podiumManager