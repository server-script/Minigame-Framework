local teleportationManager = {}

-- MODULES --
local commonUtils = require(game.ReplicatedStorage.Utils.CommonUtils)

-- VARIABLES --
--/Settings
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

--/References
local teleportationPoints = workspace.Hub.TeleportPoints


-- PUBLIC METHODS --
function teleportationManager.TeleportPlayer(player, teleportName)
	local playerGamemode = player:GetAttribute(PLAYER_GAMEMODE_ATTRIBUTE)
	local teleportReference = teleportationPoints:FindFirstChild(teleportName)
	local rootPart = commonUtils.GetPlayerRootPart(player)
	local humanoid = commonUtils.GetPlayerHumanoid(player)

	if playerGamemode ~= playerGamemodeType.Hub or not teleportReference or not rootPart or not humanoid or humanoid.Health <= 0 then return end

	rootPart.CFrame = teleportReference.CFrame * CFrame.new(0, (humanoid.HipHeight + rootPart.Size.Y/2) * Vector3.yAxis,0)
end

-- INITIALIZE --
function Initialize()
	requestTeleportRemote.OnServerInvoke = teleportationManager.TeleportPlayer
end
Initialize()

return teleportationManager
