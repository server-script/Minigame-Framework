--[[
This script manages all the monetary transactions and player's wallets. Additionally, this script allows you to
add, remove or modify the player's currency multipliers!
]]

local MoneyManager = {}

-- REQUIREMENTS --
local DatastoreManager = require(script.Parent.DatastoreManager)
local replicatedStorage = game:GetService("ReplicatedStorage")

-- VARIALBES --
--/Remote Events
local remotesFolder = replicatedStorage.Remotes
local moneyRemotes = remotesFolder.MoneyManager
local currencyChangedEvent = moneyRemotes.CurrencyChanged
local getCurrencyEvent = moneyRemotes.GetCurrency

--/Public Events
local currencyChangedLocalEvent = Instance.new("BindableEvent")
MoneyManager.CurrencyChanged = currencyChangedLocalEvent.Event

--/Constants
local GLOBAL_MONEY_MULTIPLIER = 1

-- METHODS --
--Adds the given amount to the selected currency. when applyMultiplier is true, the global and player multipliers are used
function MoneyManager:AddFunds(player, currency, amount, applyMultiplier)
	if amount == 0 then return end
	DatastoreManager:WaitForPlayerDataLoaded(player)
	local playerWallet = DatastoreManager[player].Data.Wallet

	local totalMultiplier = applyMultiplier == false and 1 or MoneyManager:CalculatePlayerMultiplier(player, currency)

	if playerWallet[currency] then
		playerWallet[currency] += amount*totalMultiplier
	else
		playerWallet[currency] = amount*totalMultiplier
	end

	currencyChangedEvent:FireClient(player, currency, MoneyManager:GetFunds(player, currency))
	currencyChangedLocalEvent:Fire(player, currency, MoneyManager:GetFunds(player, currency))
	return amount*totalMultiplier
end

--Removes the given amount from the selected currency. Cannot go below 0
function MoneyManager:SpendFunds(player, currency, amount)
	if amount == 0 then return end
	DatastoreManager:WaitForPlayerDataLoaded(player)
	local playerWallet = DatastoreManager[player].Data.Wallet

	if playerWallet[currency] then
		playerWallet[currency] = math.max(playerWallet[currency] - amount,0)
	else
		playerWallet[currency] = 0
	end

	currencyChangedEvent:FireClient(player, currency, MoneyManager:GetFunds(player, currency))
	currencyChangedLocalEvent:Fire(player, currency, MoneyManager:GetFunds(player, currency))
end

--Returns the amount of currency the player has, use this before any removal transaction
function MoneyManager:GetFunds(player, currency)
	DatastoreManager:WaitForPlayerDataLoaded(player)
	local playerWallet = DatastoreManager[player].Data.Wallet
	
	return playerWallet[currency] or 0
end

function MoneyManager:AddMultiplier(player, currency, multiplier, duration, id)
	DatastoreManager:WaitForPlayerDataLoaded(player)
	local playerMultipliers = DatastoreManager[player].Data.MoneyMultipliers

	if not playerMultipliers[currency] then
		playerMultipliers[currency] = {}
	end

	for i, multiplierInfo in pairs(playerMultipliers[currency]) do
		local timeSinceBoostStart = os.time() - multiplierInfo.StartTime
		if multiplierInfo.Id == id then
			if timeSinceBoostStart > multiplierInfo.Duration then
				table.remove(playerMultipliers[currency], i)
			else
				warn("AddMultiplier() ERROR: You tried to add a multiplier id that was already there. Change the ID or use ModifyMultiplier()")
				return	
			end
		end
	end

	table.insert(playerMultipliers[currency], {
		Id = id,
		Multiplier = multiplier,
		Duration = duration,
		StartTime = os.time()
	})
end

--Removes a multiplier, given its ID and currency. Currency is important because you may have the same Id in multiple places
function MoneyManager:RemoveMultiplier(player, currency, id)
	DatastoreManager:WaitForPlayerDataLoaded(player)
	local playerMultipliers = DatastoreManager[player].Data.MoneyMultipliers

	if not playerMultipliers[currency] then
		return
	end

	for i, multiplierInfo in pairs(playerMultipliers[currency]) do
		if multiplierInfo.Id == id then
			table.remove(playerMultipliers[currency], i)
			return
		end
	end
end

function MoneyManager:MofidyMultiplier(player, currency, multiplier, duration, id)
	DatastoreManager:WaitForPlayerDataLoaded(player)
	local playerMultipliers = DatastoreManager[player].Data.MoneyMultipliers

	if not playerMultipliers[currency] then
		warn("ModifyMultiplier(): multiplier ID not found, the table is empty")
		return
	end
	for i, multiplierInfo in pairs(playerMultipliers[currency]) do
		local timeSinceBoostStart = os.time() - multiplierInfo.StartTime
		if multiplierInfo.Id == id and timeSinceBoostStart > multiplierInfo.Duration then
			table.remove(playerMultipliers[currency], i)
		end
	end

	for i, multiplierInfo in pairs(playerMultipliers[currency]) do
		if multiplierInfo.Id == id then
			multiplierInfo.Multiplier = multiplier
			multiplierInfo.Duration = duration
			return
		end
	end

	warn("ModifyMultiplier(): multiplier ID not found, a match was not in the table")
end

function MoneyManager:IncreaseMultiplierDuration(player, currency, id, duration)
	DatastoreManager:WaitForPlayerDataLoaded(player)
	local playerMultipliers = DatastoreManager[player].Data.MoneyMultipliers

	if not playerMultipliers[currency] then
		warn("IncreaseMultiplierDuration(): multiplier ID not found, the table is empty")
		return
	end
	for i, multiplierInfo in pairs(playerMultipliers[currency]) do
		local timeSinceBoostStart = os.time() - multiplierInfo.StartTime
		if multiplierInfo.Id == id and timeSinceBoostStart > multiplierInfo.Duration then
			table.remove(playerMultipliers[currency], i)
		end
	end

	for i, multiplierInfo in pairs(playerMultipliers[currency]) do
		if multiplierInfo.Id == id then
			local timeSinceBoostStart = os.time() - multiplierInfo.StartTime
			if timeSinceBoostStart <= multiplierInfo.Duration then
				multiplierInfo.Duration += duration
			end
			return
		end
	end

	warn("IncreaseMultiplierDuration(): multiplier ID not found, the ID is not in the table")
end

function MoneyManager:GetActiveMultipliers(player, currency)
	DatastoreManager:WaitForPlayerDataLoaded(player)
	local playerMultipliers = DatastoreManager[player].Data.MoneyMultipliers

	if not playerMultipliers[currency] then
		return {}
	end

	local result = {}
	for i, multiplierInfo in pairs(playerMultipliers[currency]) do
		local timeSinceBoostStart = os.time() - multiplierInfo.StartTime
		if timeSinceBoostStart <= multiplierInfo.Duration then
			result[multiplierInfo.Id] = {
				TimeLeft = multiplierInfo.Duration - timeSinceBoostStart,
				Multiplier = multiplierInfo.Multiplier
			}
		end
	end

	return result
end

function MoneyManager:CalculatePlayerMultiplier(player, currency)
	DatastoreManager:WaitForPlayerDataLoaded(player)
	local playerMultipliers = DatastoreManager[player].Data.MoneyMultipliers

	local totalMultiplier = GLOBAL_MONEY_MULTIPLIER
	if playerMultipliers[currency] then
		--Cycles through every active player-specific multiplier, making sure they are not expired, and applying them
		for _, multiplierInfo in pairs(playerMultipliers[currency]) do
			local timeSinceBoostStart = os.time() - multiplierInfo.StartTime
			if timeSinceBoostStart <= multiplierInfo.Duration then
				totalMultiplier += (multiplierInfo.Multiplier - 1)
			end
		end
	end

	return totalMultiplier
end

function MoneyManager:DebugFunds(player)
	DatastoreManager:WaitForPlayerDataLoaded(player)
	local playerWallet = DatastoreManager[player].Data.Wallet

	warn("DebugFunds(): The currencies and money", player, "owns are", playerWallet)
end

-- CONNECTIONS --
getCurrencyEvent.OnServerInvoke = function(...) return MoneyManager:GetFunds(...) end



return MoneyManager
