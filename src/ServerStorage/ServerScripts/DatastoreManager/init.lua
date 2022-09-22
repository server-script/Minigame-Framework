--[[

info: This script is a wrapper for the ProfileService, You most likely won't need this, 
		but in order to get the data do:
		require(DataStoreManager)[player].Data
		You can see all of the data variables contained in this Data table down below in
		the variable ProfileTemplate
	
	Collaborators: Orodex, DEV_Sal
]]

-- SERVICES --
local players = game:GetService("Players")

-- REQUIRES --
local ProfileService = require(script.ProfileService)
local testManager = require(game.ReplicatedStorage.SharedModules.TestManager)

-- VARIABLES --
--/Tables
local ProfileTemplate = {
	Wallet = {},
	MoneyMultipliers = {},
	
	Inventory = {
		Tools = {},

		EquippedTools = {},

		--ChatTags = {},
		--ChatColors = {},
		--NameColors = {},
	},
}

--/References
local datastoreManager = {}
local GameProfileStore = ProfileService.GetProfileStore(testManager.TestMode and testManager.TestId.."TestProfiles" or "ReleaseProfiles", ProfileTemplate)

--/Public Events
local PlayerDataLoadedEvent = Instance.new("BindableEvent")
local PlayerDataUnloadedEvent = Instance.new("BindableEvent")
datastoreManager.PlayerDataLoaded = PlayerDataLoadedEvent.Event
datastoreManager.PlayerDataUnloaded = PlayerDataUnloadedEvent.Event

-- PUBLIC METHODS --
function datastoreManager:PlayerDataIsLoaded(player)
	if not player then warn("DATASTORE CALL ERROR: You are asking if a nil player has loaded their data.") end
	
	return datastoreManager[player] ~= nil and datastoreManager[player]:IsActive()
end

function datastoreManager:WaitForPlayerDataLoaded(player)
	if not player then warn("DATASTORE CALL ERROR: You are waiting for a nil player") end
	
	if not datastoreManager:PlayerDataIsLoaded(player) then
		repeat
			local newLoadedPlayer = datastoreManager.PlayerDataLoaded:Wait()
			--warn(newLoadedPlayer, "loaded. Was it the player I wanted?", player, newLoadedPlayer == player)
			if newLoadedPlayer == player then
				break
			end
		until false
	end
end

function datastoreManager:FindPlayerProfile(UserId)
	if typeof(UserId) == "Instance" and game.Players:FindFirstChild(UserId.Name) then
		UserId = UserId.UserId
	end
	
	return GameProfileStore:ViewProfileAsync("Player_" ..UserId)
end

--/ GLOBAL UPDATES \--
--/This function allows the developer to listen/read data profiles from other modules
function datastoreManager:GetProfileStore(player)
	return GameProfileStore
end

function datastoreManager:AddActiveGiftUpdate(fromPlayer, toPlayerUserId, ProductId, isGamepass)
	local profileKey = "Player_"..toPlayerUserId
	local purchaseType
	
	if isGamepass then
		purchaseType = "Gamepass"
	else
		purchaseType = "DevProduct"
	end
	
	GameProfileStore:GlobalUpdateProfileAsync(
		profileKey,
		function(globalUpdates)
			globalUpdates:AddActiveUpdate(
				{
					UpdateType = "PurchaseGift",
					PurchaseType = purchaseType,
					PurchaseSender = fromPlayer.Name,
					ProductId = ProductId,
					SendTime = os.time()
					
				}
			)
		end
	)
	
	return
	
end
--\ GLOBAL UPDATES /--

-- PRIVATE FUNCTIONS --

--/ GLOBAL UPDATES \--
local function HandleUpdate(player, globalUpdates, update)
	local updateId = update[1]
	local updateData = update[2]
	
	if not updateData.UpdateType then warn("GlobalUpdate type was not specified") return end
	
	if updateData.UpdateType == "PurchaseGift" then
		if not updateData.PurchaseType then warn("PurchaseGift is nil") return end
		if not updateData.PurchaseSender then warn("PurchaseSender is nil") return end
		if not updateData.ProductId then warn("ProductId is nil") return end
		
		if updateData.PurchaseType == "Gamepass" then
			
			require(script.Parent.GiftingManager).GiftReceived(player.UserId, updateData.PurchaseSender, updateData.ProductId, true)
		elseif updateData.PurchaseType == "DevProduct" then
			
			warn("PLAYER RECEIVED GIFT! SENDING TO GIFTRECEIVED NOW!")
			require(script.Parent.GiftingManager).GiftReceived(player.UserId, updateData.PurchaseSender, updateData.ProductId)
		end
		
	elseif updateData.UpdateType == "SomethingOtherThanAGift" then
		warn("do stuff here")
	end
	
	globalUpdates:ClearLockedUpdate(updateId)
end
--\ GLOBAL UPDATES /--

local function OnPlayerDataLoaded(player)
	local profile = datastoreManager[player]
	repeat wait() until profile:IsActive()
	PlayerDataLoadedEvent:Fire(player)
end

local function PlayerAdded(player)
	local profile = GameProfileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")
	
	if profile ~= nil then
		profile:ListenToRelease(function()
			datastoreManager[player] = nil
			PlayerDataUnloadedEvent:Fire(player)
			player:Kick("\nYour saved data was loaded remotely. You have been kicked to prevent data corruption, please rejoin. If the problem persists please contact a developer")
		end)
		if player:IsDescendantOf(players) == true then
			profile:Reconcile()
			datastoreManager[player] = profile
			OnPlayerDataLoaded(player)
			
			--/ GLOBAL UPDATES \--
			local globalUpdates = profile.GlobalUpdates
			
			for _, update in pairs(globalUpdates:GetActiveUpdates()) do
				globalUpdates:LockActiveUpdate(update[1])
			end
			
			for _, update in pairs(globalUpdates:GetLockedUpdates()) do
				HandleUpdate(player, globalUpdates, update)
			end

			globalUpdates:ListenToNewActiveUpdate(function(updateId, updateData)
				globalUpdates:LockActiveUpdate(updateId)
			end)

			globalUpdates:ListenToNewLockedUpdate(function(updateId, updateData)
				HandleUpdate(player, globalUpdates, {updateId, updateData})
			end)
			
			--\ GLOBAL UPDATES /--
			
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		player:Kick("\nWe were unable to load your saved data. Please rejoin! If the problem persists please contact a developer") 
	end
end

-- CONNECTIONS --

players.PlayerAdded:Connect(PlayerAdded)

players.PlayerRemoving:Connect(function(player)
	local profile = datastoreManager[player]
	if profile ~= nil then
		profile:Release()
	end
end)

-- INITIALIZE --

for _, player in ipairs(players:GetPlayers()) do --Makes sure the player wasn't already in the game before the DatastoreManager
	coroutine.wrap(function()
		PlayerAdded(player)
	end)()
end

return datastoreManager