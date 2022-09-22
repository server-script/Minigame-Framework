local SRTParser = {}

-- VARIABLES --
--/Settings
local FADE_THRESHOLD = .2
local FADEINOUT_DURATION = .2


-- PUBLIC METHODS --
function SRTParser.ParseSRT(source)
	local result = {}
	local globalIndex = 1
	local tableIndex = 1
	for subText in string.gmatch(source,"[^\r\n]+") do

		local localIndex = Repeat1Up(globalIndex, 3)

		-- Obtain the index of the subtitle section
		if localIndex == 1 then
			tableIndex = tonumber(subText)
			result[tableIndex] = {}

		-- Obtain the time from the second line
		elseif localIndex == 2 then

			--Split the string by spaces and keep only the 1st and 3rd
			local timeTextCount = 1
			for timeText in string.gmatch(subText, "%S+") do

				if timeTextCount == 1 or timeTextCount == 3 then

					--Split the string by punctuation, obtaining in order hours, minutes, seconds, and centiseconds. Convert everything in just seconds
					local subTimeCount = 1
					local totalSubTime = 0
					for subTime in string.gmatch(timeText, "%P+") do
						if subTimeCount == 1 then
							totalSubTime += tonumber(subTime) * 3600
						elseif subTimeCount == 2 then
							totalSubTime += tonumber(subTime) * 60
						elseif subTimeCount == 3 then
							totalSubTime += tonumber(subTime)
						elseif subTimeCount == 4 then
							totalSubTime += tonumber(subTime) / 1000
						end

						subTimeCount+=1
					end

					if timeTextCount == 1 then
						if tableIndex == 1 then
							result[tableIndex].FadeIn = FADEINOUT_DURATION
						end
						
						if result[tableIndex-1] then
							local timeDistance = totalSubTime - result[tableIndex-1].End
							if timeDistance >= FADE_THRESHOLD then
								result[tableIndex-1].FadeOut = FADEINOUT_DURATION
								result[tableIndex-1].End += FADEINOUT_DURATION/2
								totalSubTime -= FADEINOUT_DURATION/2
								result[tableIndex].FadeIn = FADEINOUT_DURATION
							end
						end

						result[tableIndex].Start = totalSubTime
					else
						result[tableIndex].End = totalSubTime
					end

				end
				timeTextCount+=1
			end

		--Obtain the text from the subtitles section
		else--if localIndex == 3 then
			result[tableIndex].Text = subText
		end

		globalIndex+=1
	end
	return result
end

-- PRIVATE FUNCTIONS --
function Repeat1Up(value, maxValue)
	return ((value-1) % maxValue) +1
end

return SRTParser
