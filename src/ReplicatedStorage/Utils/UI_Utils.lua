--[[
	About: This module has some useful ui utils

	Collaborators: DEV_Sal
	
	--/make it so that you can add specific feedback functions to a button
	--/make list to add buttons to
	--/add functions to the button inside of the table, and loop through all the buttons and connect their functions when added
	--/make it so u can send a table of buttons, or a single button to the add function
	
	
	--/List of useful feedback functions
	MouseLeaveOriginalPosition
	MouseUpOriginalPosition
	FeedbackDown
	MouseEnterUpOffset
	
	
--]]

local Util = {}

-- SERVICES --
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

-- MODULES --
local springClass = require(game.ReplicatedStorage.Utils.SpringClass)

-- VARIABLES --
--/Settings
local DEFAULT_GLARE_DURATION = 2.5
local DEFAULT_GLARE_DELAY = 6

--/References

--/Holders
local buttonList = {}

local originalPositions = {}
local originalSizes = {}

local springUpdates = {}
local activeSprings = {}

local activeGlareEffects = {}

local feedbackFunctionList = {
	"MouseLeaveOriginalPosition",
	"MouseUpOriginalPosition",
	"PressToShadow",
	"MouseEnterUpOffset",
	"MouseEnterGrow",
	"MouseLeaveOriginalSize",
	"MouseEnterSpringEffect"
}


-- PRIVATE FUNCTIONS --

-- PUBLIC METHODS --


--/ ButtonInstance, {"MouseLeaveOriginalPosition", "MouseUpOriginalPosition", "FeedbackDown", "MouseEnterUpOffset"}
--/ ButtonInstance, {"AllFeedbacks"}
function Util.AddFeedbackFunctions(button, buttonFunctions)
	
	--/Add original properties to corresponding list
	originalPositions[button] = button.Position
	originalSizes[button] = button.Size
	
	--/Make sure button is listed in table
	if not buttonList[button] then
		buttonList[button] = {}
	end
	
	if buttonFunctions[1] == "AllFeedbacks" then
		table.remove(buttonFunctions, 1)
		for _, functionName in pairs(feedbackFunctionList) do
			table.insert(buttonFunctions, functionName)
		end
	end
	
	--/Make sure the function wanted, is available
	for _, buttonFunction in pairs(buttonFunctions) do
		if not table.find(feedbackFunctionList, buttonFunction) then
			warn(buttonFunction, " - is not a valid feedback function")
		end
		
		--/Insert button's function in list
		if not table.find(buttonList[button], buttonFunction) then
			table.insert(buttonList[button], buttonFunction)
			
			--/Start connecting functions to button
			if buttonFunction == "MouseLeaveOriginalPosition" then
				button.MouseLeave:Connect(function()
					if not button:GetAttribute("TransitionDebounce") then
						Util.OriginalPosition(button)
					end
				end)
				
			elseif buttonFunction == "MouseUpOriginalPosition" then
				button.MouseButton1Up:Connect(function()
					Util.OriginalPosition(button)
				end)
				
			elseif buttonFunction == "PressToShadow" then
				button.MouseButton1Down:Connect(function()
					Util.PressToShadow(button)
				end)
				
			elseif buttonFunction == "MouseEnterUpOffset" then
				button.MouseEnter:Connect(function()
					if not button:GetAttribute("TransitionDebounce") then
						Util.OffsetUpwards(button)
					end
				end)
				
			elseif buttonFunction == "MouseEnterGrow" then
				button.MouseEnter:Connect(function()
					if not button:GetAttribute("TransitionDebounce") then
						Util.ButtonGrow(button)
					end
				end)
				
			elseif buttonFunction == "MouseLeaveOriginalSize" then
				button.MouseLeave:Connect(function()
					if not button:GetAttribute("TransitionDebounce") then
						Util.OriginalSize(button)
					end
				end)
				
			elseif buttonFunction == "MouseEnterSpringEffect" then
				button.MouseEnter:Connect(function()
					if not button:GetAttribute("TransitionDebounce") then
						Util.SpringEffect(button)
					end
				end)
			end
			
		end
	end
end

function Util.OriginalPosition(button)
	if not originalPositions[button] then return end

	local originalPosition = originalPositions[button]

	button:TweenPosition(originalPosition, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.05, true)
end

function Util.PressToShadow(button)
	local shadowObjectValue = button:FindFirstChildOfClass("ObjectValue")
	local buttonShadow = shadowObjectValue ~= nil and shadowObjectValue.Value
	local shadowPosition = buttonShadow.Position

	button:TweenPosition(shadowPosition, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.05, true)
end

function Util.OffsetUpwards(button)
	if button.Position ~= originalPositions[button] then
		return
	end
	
	local feedbackUpOffset = button.Position - UDim2.new(0, 0, 0, 5)

	button:TweenPosition(feedbackUpOffset, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.05, true)
end

function Util.OriginalSize(button)
	if not originalSizes[button] then return end
	if button:GetAttribute("TemporaryIgnoreOriginalSize") == true then return end

	local originalSize = originalSizes[button]

	button:TweenSize(originalSize, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.05, true)
end

function Util.ButtonGrow(button)
	if button.Size ~= originalSizes[button] then
		return
	end
	
	if button:GetAttribute("TemporaryIgnoreOriginalSize") == true then return end
	local growOffset = button.Size + UDim2.new(0, 10, 0, 10)

	button:TweenSize(growOffset, Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.1, true)
end

function Util.SpringEffect(button)
	
	local spring = activeSprings[button]
	
	if not spring then
		spring = springClass.new(nil, nil, 2, 6)
		activeSprings[button] = spring
	end
	
	spring:Shove(10)
	
	local springConnection = springUpdates[button]
	
	if not springConnection then
		springUpdates[button] = runService.RenderStepped:Connect(function(deltaTime)
			spring:Update(deltaTime)
			button.Rotation = spring.Position * 10

			if math.abs(spring.Position) < 0.08 and math.abs(spring.Velocity) < 0.08 then
				springUpdates[button]:Disconnect()
				springUpdates[button] = nil
				return
			end
		end)
	end
end

function Util.AddGlareEffect(textLabel, glareDuration, timeBetweenGlares)
	if activeGlareEffects[textLabel] then return end
	
	--/Set data that isnt given
	glareDuration = glareDuration or DEFAULT_GLARE_DURATION
	timeBetweenGlares = timeBetweenGlares or DEFAULT_GLARE_DELAY
	
	--/Add to table
	activeGlareEffects[textLabel] = {timeBetweenGlares, glareDuration, tick()}
end

function Util.ClearGlareEffect(button)
	if activeGlareEffects[button] then
		activeGlareEffects[button] = nil
	end
end

function Util.TweenGradientOffset(instance, vector2, duration)
	local tweenInfo = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	tweenService:Create(instance, tweenInfo, {Offset = vector2}):Play()
end

function Util.TweenBackgroundColor(instance, color, duration)
	local tweenInfo = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	tweenService:Create(instance, tweenInfo, {BackgroundColor3 = color}):Play()
end

function Util.TweenImageColor(instance, color, duration)
	local tweenInfo = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	tweenService:Create(instance, tweenInfo, {ImageColor3 = color}):Play()
end

function Util.TweenBackgroundTransparency(instance, transparency, duration)
	local tweenInfo = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	tweenService:Create(instance, tweenInfo, {BackgroundTransparency = transparency}):Play()
end

function Util.TweenImageTransparency(instance, transparency, duration)
	local tweenInfo = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	tweenService:Create(instance, tweenInfo, {ImageTransparency = transparency}):Play()
end

function Util.TweenSize(instance, size, direction, style, duration, bool, callback)
	instance:TweenSize(size, direction, style, duration, bool, callback)
	originalSizes[instance] = size
end

function Util.TweenPosition(instance, position, direction, style, duration, bool, callback)
	instance:TweenPosition(position, direction, style, duration, bool, callback)
	originalPositions[instance] = position
end

function Util.SetTransitioningDebounce(object, bool)
	object:SetAttribute("TransitionDebounce", bool)
end

function Util.PlayGlareEffect(object, glareDuration)
	--/Make sure object has a glare effect
	local uiGradient = object:FindFirstChild("GlareEffect")
	if not uiGradient then
		warn(object, "does not have a UI Gradient effect")
		return
	end
	
	--/Don't let offset be over ridden
	if uiGradient.Offset ~= Vector2.new(0, 6) then
		return
	end
	
	--/Do glare
	uiGradient.Offset = Vector2.new(0, -6)
	Util.TweenGradientOffset(uiGradient, Vector2.new(0, 6), glareDuration or DEFAULT_GLARE_DURATION)
end

-- CONNECTIONS --
runService.RenderStepped:Connect(function()
	--/Active glares
	for textLabel, glareData in pairs(activeGlareEffects) do
		--/Set up variables
		local timeBetweenGlares = glareData[1]
		local glareDuration = glareData[2]
		local lastTick = glareData[3]
		
		--/Run glare effects
		if tick() - lastTick >= timeBetweenGlares then
			activeGlareEffects[textLabel] = {timeBetweenGlares, glareDuration, tick()}
			
			Util.PlayGlareEffect(textLabel, glareDuration or DEFAULT_GLARE_DURATION)
		end
	end
end)

-- INITIALIZE --

-- DEBUGGING --
--local oldTime = tick()
--runService.Heartbeat:Connect(function()
--	if tick() - oldTime >= 1 then
--		oldTime = tick()
--		warn(openTabs)
--	end
--end)

return Util