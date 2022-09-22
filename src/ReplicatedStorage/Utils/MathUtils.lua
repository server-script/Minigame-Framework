local MUtil = {}

MUtil.Deg2Rad = math.pi * 2 / 360;
	
MUtil.Rad2Deg = 1 / MUtil.Deg2Rad;

MUtil.Epsilon = 1e-9

MUtil.Phi = (math.sqrt(5)+1)/2

function MUtil.Clamp(value, min, max)
	return math.clamp(value, min, max)
end

function MUtil.Clamp01(value)
	if value < 0 then
		return 0
	elseif value > 1 then
		return 1
	else
		return value
	end
end

function MUtil.PingPong(value, maxValue)
	value = MUtil.Repeat(value, maxValue * 2)
	return maxValue - math.abs(value - maxValue)
end

function MUtil.Repeat(value, maxValue)
	return value % maxValue
end

function MUtil.Repeat1Up(value, maxValue)
	return ((value-1) % maxValue) +1
end

function MUtil.MapRange(value, oldRangeMin, oldRangeMax, newRageMin, newRangeMax)
	return ((value-oldRangeMin)/(oldRangeMax-oldRangeMin))*(newRangeMax-newRageMin)+newRageMin;
end

function MUtil.Lerp(start, target, alpha)
	return start + (target - start) * MUtil.Clamp01(alpha)
end

function MUtil.LerpUnclamped(start, target, alpha)
	return start + (target - start) * alpha;
end

function MUtil.LerpAngle(start, target, alpha)
	local delta = MUtil.Repeat((target - start), 360)
	if delta > 180 then
		delta -= 360
	end
	return start + delta * MUtil.Clamp01(alpha)
end

function MUtil.MoveTowards(current, target, maxDelta)
	if math.abs(target - current) <= maxDelta then 
		return target
	end
	return current + math.sign(target - current) * maxDelta
end

function MUtil.FormatSeconds(realSeconds)
	local seconds = math.floor(realSeconds % 60)
	local minutes = math.floor(realSeconds/60 % 60)
	local hours = math.floor(realSeconds/3600 % 24)
	local days = math.floor(realSeconds/86400)
	
	local output = ""
	if days > 0 then
		output = output..tostring(days)..":"
	end
	if days > 0 or hours > 0 then
		output = output..string.format("%0.2i", hours) .. ":"
	end
	if minutes then
		output = output..string.format("%0.2i", minutes)
	end
	if seconds then
		output = output..":"..string.format("%0.2i", seconds)
	end
	
	return output
end

function MUtil.RandomFromWeightTable(weightTable)
	local total = 0
	for _, weight in pairs(weightTable) do
		total+= weight
	end

	local picked = math.random() * total

	local pickCounter = 0
	local pickedItem 
	for item, weight in pairs(weightTable) do
		pickCounter += weight
		if picked <= pickCounter then
			pickedItem = item
			break
		end
	end

	return pickedItem
end

function MUtil.MoveTowardsAngle(current, target, maxDelta)
	local deltaAngle = MUtil.DeltaAngle(current, target)
	if -maxDelta < deltaAngle and deltaAngle < maxDelta then
		return target
	end
	target = current + deltaAngle
	return MUtil.MoveTowards(current, target, maxDelta)
end

function MUtil.DeltaAngle(current, target)
	return math.atan2(math.sin(math.rad(target)-math.rad(current)), math.cos(math.rad(target)-math.rad(current))) * MUtil.Rad2Deg --delta
end

function MUtil.NormalizeAngle(angle, start, finish)
	local width = finish - start
	local offsetValue = angle - start

	return (offsetValue - (math.floor(offsetValue / width) * width)) + start
end

function MUtil.SmoothDamp(current, target, currentVelocity, smoothTime, maxSpeed, deltaTime)
	smoothTime = math.max(0.0001, smoothTime)
	local omega = 2 / smoothTime
	
	local x = omega * deltaTime
	local exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
	local change = current - target
	local originalTo = target
	
	local maxChange = maxSpeed * smoothTime
	change = math.clamp(change, -maxChange, maxChange)
	target = current - change
	
	local temp = (currentVelocity + omega * change) * deltaTime
	currentVelocity = (currentVelocity - omega * temp) * exp
	local output = target + (change + temp) * exp
	
	if (originalTo - current > 0) == (output > originalTo) then
		output = originalTo
		currentVelocity = (output - originalTo) / deltaTime
	end
		
	return output, currentVelocity
end

function MUtil.SmoothDampAngle(current, target, currentVelocity, smoothTime, maxSpeed, deltaTime)
	target = current + MUtil.DeltaAngle(current, target)
	return MUtil.SmoothDamp(current, target, currentVelocity, smoothTime, maxSpeed, deltaTime)
end

function MUtil.TruncateNumber(value, digits)
	local divisor = 10^digits
	return math.round(value*divisor)/divisor
end

return MUtil
