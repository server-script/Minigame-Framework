local dateUtils = {}

local monthDays = { 31, 28, 31,
	30, 31, 30,
	31, 31, 30,
	31, 30, 31 };

-- This function counts number of
-- leap years before the given date
function dateUtils.CountLeapYears(date)
	local years = date.year

	if date.month <= 2 then
		years -= 1
	end

	return years / 4
	- years / 100
	+ years / 400
end

function dateUtils.GetTotalDays(date) --since first monday of day 0
	local total = date.year * 365 + date.day

	for i = 1, date.month-1 do
		total += monthDays[i]
	end

	total += dateUtils.CountLeapYears(date)
	return math.floor(total+5)
end

function dateUtils.GetTotalWeeks(date) -- since first monday of day 0
	local total = date.year * 365 + date.day

	for i = 1, date.month-1 do
		total += monthDays[i]
	end

	total += dateUtils.CountLeapYears(date)
	return math.floor(math.floor(total)/7+0.7143)
end

function dateUtils.GetTotalDaysFromTime(ostime)
	local date = os.date("*t", ostime)
	return dateUtils.GetTotalDays(date)
end

function dateUtils.GetTotalWeeksFromTime(ostime)
	local date = os.date("*t", ostime)
	return dateUtils.GetTotalWeeks(date)
end

function dateUtils.GetDifference(date1, date2)
	return dateUtils.GetTotalDays(date2) - dateUtils.GetTotalDays(date1)
end

function dateUtils.GetDifferenceFromTimes(ostime1, ostime2)
	return dateUtils.GetTotalDaysFromTime(ostime1) - dateUtils.GetTotalDaysFromTime(ostime2)
end

function dateUtils.GetLocalOffsetFromUTC()
	return math.floor(tonumber(os.date("%z", os.time()))/100)*3600
end

function dateUtils.ClampTimezoneOffset(offset)
	return math.clamp(offset, -12*3600, 14*3600)
end

return dateUtils