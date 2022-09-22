local SubtitlesUtils = {}

-- SERVICES --
local runService = game:GetService("RunService")

-- REQUIRES --
local SRTParser = require(script.SRTParser)

-- VARIABLES --
--holders
SubtitlesUtils.SubtitlesEnabled = true
local activeAudios = {}
local subtitleCount = 0
local playID = 0

--/references
local localPlayer = game.Players.LocalPlayer
local subtitlesUI = script.Subtitles



-- PUBLIC FUNCTIONS --
function SubtitlesUtils.SetSubtitlesEnabled(enabled)
	SubtitlesUtils.SubtitlesEnabled = enabled
end

function SubtitlesUtils.StartSubtitles(sound)
	playID += 1
	local localID = playID
	--Get the subtitles
	local subtitlesScript = sound:FindFirstChild("Subtitles")
	if not subtitlesScript then
		warn("[SUBTITLES_UTILS]", sound, "is missing subtitles! Aborting.")
		return
	end
	local subtitlesRaw = require(subtitlesScript)
	local subtitles
	if subtitlesRaw.Type == "SRT" then
		subtitles = SRTParser.ParseSRT(subtitlesRaw.Text)
	else
		subtitles = subtitlesRaw
	end
	--
	
	activeAudios[localID] = {Connections = {}, SubtitlesShown = {}}
	
	--Start scanning
	if sound.IsPlaying then
		EnableSubtitlesUpdate(sound, subtitles, localID)
	else
		local soundEnabledConnection
		soundEnabledConnection = sound.Played:Connect(function()
			soundEnabledConnection:Disconnect()
			table.remove(activeAudios[localID].Connections ,table.find(activeAudios[localID].Connections, soundEnabledConnection))
			EnableSubtitlesUpdate(sound, subtitles, localID)
		end)
		table.insert(activeAudios[localID].Connections, soundEnabledConnection)
	end
end

-- PRIVATE FUNCTIONS --
function EnableSubtitlesUpdate(sound, subtitles, localID)
	warn("Enabling update")
	
	local subtitlesUpdate
	subtitlesUpdate = runService.RenderStepped:Connect(function()
		if not sound.IsPlaying then
			DisableSubtitledUpdate(localID)
			return
		end
		
		local timeStamp = sound.TimePosition
		for _, subtitle in ipairs(subtitles) do
			--Check for removal
			if timeStamp > subtitle.End or timeStamp < subtitle.Start then
				if activeAudios[localID].SubtitlesShown[subtitle] then
					activeAudios[localID].SubtitlesShown[subtitle]:Destroy()
					activeAudios[localID].SubtitlesShown[subtitle] = nil
				end
				continue
			end
			--
			
			if timeStamp < subtitle.End then
				--Check for addition
				if not activeAudios[localID].SubtitlesShown[subtitle] then
					warn("Adding new subtitle")
					local newSubtitle = subtitlesUI:WaitForChild("Prefabs").SubtitleLabel:Clone()
					newSubtitle.Text = subtitle.Text
					newSubtitle.Visible = true
					newSubtitle.Parent = subtitlesUI.Holder
					activeAudios[localID].SubtitlesShown[subtitle] = newSubtitle
				end
				--
				
				local subtitleLabel = activeAudios[localID].SubtitlesShown[subtitle]
				local localTimePosition = timeStamp - subtitle.Start
				
				--Calculate Transparency
				local transparency
					--Apply FadeIn
				if subtitle.FadeIn and localTimePosition < subtitle.FadeIn then
					transparency = 1-localTimePosition/subtitle.FadeIn
					--Apply FadeOut
				elseif subtitle.FadeOut and localTimePosition > subtitle.FadeOut then
					local subtitleDuration = subtitle.End - subtitle.Start
					transparency = (localTimePosition - (subtitleDuration - subtitle.FadeOut)) /subtitle.FadeOut
				else
					transparency = 0
				end
				--
				subtitleLabel.TextTransparency = transparency
				subtitleLabel.TextStrokeTransparency = transparency
			end
		end
	end)
	
	table.insert(activeAudios[localID].Connections, subtitlesUpdate)
end

function DisableSubtitledUpdate(localID)
	
	for _, subtitle in pairs(activeAudios[localID].SubtitlesShown) do
		subtitle:Destroy()
	end
	
	for _, connection in pairs(activeAudios[localID].Connections) do
		connection:Disconnect()
	end
	
	activeAudios[localID] = nil
end

-- INITIALIZE --
function Initialize()
	subtitlesUI.Parent = localPlayer.PlayerGui
end
Initialize()

return SubtitlesUtils
