local draw = require(script:WaitForChild("draw"));

local drawClass = {};
local drawClass_mt = {__index = drawClass};
local storage = setmetatable({}, {__mode = "k"});

function drawClass.new()
	local self = {};
	
	for k, func in next, draw do
		self[k] = function(...)
			local t = {func(...)};
			for i = 1, #t do
				table.insert(storage[self], t[i]);
			end
			return unpack(t);
		end
	end
	
	storage[self] = {};
	return setmetatable(self, drawClass_mt);
end

function drawClass:clear()
	local t = storage[self];
	while (#t > 0) do
		table.remove(t):Destroy();
	end
	storage[self] = {};
end

return drawClass;