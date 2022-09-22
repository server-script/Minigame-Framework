local errorsUtils = {}

function errorsUtils.AttemptMultipleTimes(functionToAttempt, timesToAttempt, timeBetweenAttempts)
	for i = 1, timesToAttempt do
		local success, functionReturn = pcall(functionToAttempt)
		
		if success then
			return functionReturn
		else
			warn("[ERROR_UTILS] Attempt Multiple Times fired error:", functionReturn, "\n Attempting", timesToAttempt-i, "more times")
			if timesToAttempt-i > 0 then
				task.wait(timeBetweenAttempts)
			else
				return success
			end
		end
	end
end

return errorsUtils
