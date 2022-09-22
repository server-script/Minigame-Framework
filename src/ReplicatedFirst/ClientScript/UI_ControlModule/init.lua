--[[
	About: This module handles all UI modules.
	
	IMPORTANT: Always use this module to open/close UI.

	Collaborators: DEV_Sal
--]]

local ControlModule = {}

local uiModules = {
	MinigameManager = script.MinigameManager,
	VotingTabManager = script.VotingTabManager,
}

-- SERVICES --

-- REQUIRES --

-- VARIABLES --
--/References
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

ControlModule.tabClosedEvent = Instance.new("BindableEvent")
ControlModule.tabOpenedEvent = Instance.new("BindableEvent")

local remotes = game.ReplicatedStorage:WaitForChild("Remotes")

local starterGuiFolder = script.Parent.Parent.StarterGui

--/Tables
local openTabs = {}

local tabCloseCallbacks = {}

-- PRIVATE FUNCTIONS --

function Initialize()
	local player = game.Players.LocalPlayer
	local playerGui = player.PlayerGui
	game:GetService("UserInputService").InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mousePos = input.Position
			local objects = playerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
			
			for tab, _ in pairs(openTabs) do
				if uiModules[tab] and uiModules[tab].CloseFromObjectsClicked then
					uiModules[tab].CloseFromObjectsClicked(objects)
				end
			end
		end
	end)
	
	game:GetService("UserInputService").TouchTap:Connect(function(touchPositions)
		local objects = playerGui:GetGuiObjectsAtPosition(touchPositions[1].X, touchPositions[1].Y)
		
		for tab, _ in pairs(openTabs) do
			if uiModules[tab] and uiModules[tab].CloseFromObjectsClicked then
				uiModules[tab].CloseFromObjectsClicked(objects)
			end
		end
	end)
	
	for _, uiObject in pairs(starterGuiFolder:GetChildren()) do
		uiObject.Parent = playerGui
	end
	
	-- Require all UI modules
	local requiresCompleted = 0
	local requiresNeeded = 0
	for name, module in pairs(uiModules) do
		requiresNeeded += 1
	end
	
	for name, module in pairs(uiModules) do
		coroutine.wrap(function()
			requiresCompleted += 1
			uiModules[name] = require(module)
			
			--/Set ControlModule requires for each module
			if uiModules[name].SetControlModule then
				uiModules[name].SetControlModule(ControlModule)
			end
		end)()
	end
	
	repeat task.wait() until requiresCompleted >= requiresNeeded
	--
	
	--/Set up UI
	
end

function ExecuteCallbacks(moduleName)
	for tab, tabCloseCallback in pairs(tabCloseCallbacks) do
		tabCloseCallback()
		tabCloseCallbacks[tab] = nil
	end
end

-- PUBLIC METHODS --

function ControlModule.OpenTab(moduleName, ignoreOpenTabs, hideHud, hideHotbar)
	
	if not ignoreOpenTabs and #openTabs > 0 then --this is untested
		--warn("There is already a tab openned")
		return
	else
		--warn("opening", moduleName)
	end
	
	if not ignoreOpenTabs then
		for tab, tabSettings in pairs(openTabs) do
			ControlModule.CloseTab(tab)
		end
	end
	
	local tabIndex = openTabs[moduleName]
	if tabIndex then
		--warn(moduleName, "is already open")
		return
	end
	
	if not uiModules[moduleName] then
		warn(moduleName, "is not a valid UI module")
		return
	end
	
	if not uiModules[moduleName].OpenTab then
		warn("Module does not have an open tab function")
		return
	end
	
	openTabs[moduleName] = {ignoreOpenTabs = ignoreOpenTabs, hideHud = hideHud, hideHotbar = hideHotbar}
	
	uiModules[moduleName].OpenTab()
	ControlModule.tabOpenedEvent:Fire()
	
end

--/This function allows you to open a tab, then when that tab is closed, it will open the previous
--/tab(s) that were already opened
function ControlModule.TemperarilyOpenTab(moduleName, hideHud, hideHotbar)
	
	--/Open temporary tab
	local tabIndex = openTabs[moduleName]
	if tabIndex then
		warn(moduleName, "is already open")
		return
	end

	if not uiModules[moduleName] then
		warn(moduleName, "is not a valid UI module")
		return
	end

	if not uiModules[moduleName].OpenTab then
		warn("Module does not have an open tab function")
		return
	end
	
	local previousOpenTabs = {}
 
	--/Insert previous tabs into table, then close them
	for tab, tabSettings in pairs(openTabs) do
		previousOpenTabs[tab] = tabSettings
		ControlModule.CloseTab(tab)
	end

	--/Bind opening previous tabs, to temporary tab closing
	ControlModule.BindActionToTabClose(moduleName, function()
		warn(moduleName, "WAS CLOSED. BINDED ACTION FIRING")
		for tab, tabSettings in pairs(previousOpenTabs) do
			ControlModule.OpenTab(tab, tabSettings.ignoreOpenTabs, tabSettings.hideHud, tabSettings.hideHotbar)
		end
	end)
	
	openTabs[moduleName] = {ignoreOpenTabs = false, hideHud = hideHud, hideHotbar = hideHotbar}

	uiModules[moduleName].OpenTab()
	ControlModule.tabOpenedEvent:Fire()
	
end

function ControlModule.CloseTab(moduleName)
	local tabIndex = openTabs[moduleName]
	if not tabIndex then
		return
	end
	
	if not uiModules[moduleName] then
		warn(moduleName, "is not a valid UI module")
		return
	end
	
	if not uiModules[moduleName].CloseTab then
		warn("Module does not have an open tab function")
		return
	end
	
	openTabs[moduleName] = nil
	uiModules[moduleName].CloseTab()
	ControlModule.tabClosedEvent:Fire()
end

function ControlModule.CloseAllTabs()
	for tab, tabSettings in pairs(openTabs) do
		ControlModule.CloseTab(tab)
	end
end

function ControlModule.BindActionToTabClose(moduleName, callback)
	tabCloseCallbacks[moduleName] = callback
end

function ControlModule.TabIsOpen(moduleName)
	if openTabs[moduleName] then
		return true
	else
		return false
	end
end


-- CONNECTIONS --

ControlModule.tabClosedEvent.Event:Connect(ExecuteCallbacks)

-- INITIALIZE --
Initialize()


-- DEBUGGING --
--local oldTime = tick()
--runService.Heartbeat:Connect(function()
--	if tick() - oldTime >= 1 then
--		oldTime = tick()
--		warn(openTabs)
--	end
--end)

return ControlModule