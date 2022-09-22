local module = {}

local suffixes = {"K", "M", "B", "T", "Qa", "Qi", "Si", "Sp", "", "", ""}

function addCommas(str)
	return #str % 3 == 0 and str:reverse():gsub("(%d%d%d)", "%1,"):reverse():sub(2) or str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

local function ToSuffixString(n)
	if tonumber(n)>9999 then
		for i = #suffixes, 1, -1 do
			local v = math.pow(10, i * 3)
			if tonumber(n) >= v then
				return ("%.1f"):format(n / v) .. suffixes[i]
			end
		end
		return tostring(n)
	else
		return addCommas(tostring(n))
	end
end

function module:toSuffixString(args)
	return ToSuffixString(args)
end

function module:AddCommas(str)
	return addCommas(tostring(str))
end

return module