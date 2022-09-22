local minigamesPortalManager = {}

-- MODULES --
local commonUtils = require(game.ReplicatedStorage.Utils.CommonUtils)
local teleportScreenManager = require(game.ReplicatedFirst.ClientScript.UI_ControlModule.TeleportationScreenManager)

-- VARIABLES --
--/Holder
local isTeleporting = false

--/References
local localPlayer = game.Players.LocalPlayer
local minigamesPortalCollider = workspace:WaitForChild("Hub"):WaitForChild("LobbyPortal"):WaitForChild("PortalCollider")

-- PRIVATE FUNCTIONS --
function OnPortalCollision(hit)
	local playerHit = game.Players:GetPlayerFromCharacter(hit.Parent)
	if playerHit == localPlayer and not isTeleporting then
		isTeleporting = true
		teleportScreenManager.TeleportToMinigames()
		task.wait(1)
		isTeleporting = false
	end
end

-- INITIALIZE --
function Initialize()
	minigamesPortalCollider.Touched:Connect(OnPortalCollision)
end
Initialize()

return minigamesPortalManager
