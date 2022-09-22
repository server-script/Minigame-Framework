local Spring = {}
Spring.__index = Spring

-- STATIC VARIABLES --
local ITERATIONS = 8

-- CONSTRUCTOR --
function Spring.new(mass, force, damping, speed)

	local self = setmetatable({
		Target = 0;
		Position = 0;
		Velocity = 0;

		Mass = mass or 5;
		Force = force or 50;
		Damping = damping or 4;
		Speed = speed  or 4;
	}, Spring)

	return self
end

-- PUBLIC FUNCTIONS --
function Spring:Shove(force)
	if force ~= force or force == math.huge or force == -math.huge then
		force = 0
	end
	self.Velocity = self.Velocity + force
end

function Spring:Update(dt)
	local scaledDeltaTime = math.min(dt,1) * self.Speed / ITERATIONS

	for i = 1, ITERATIONS do
		local iterationForce= self.Target - self.Position
		local acceleration = (iterationForce * self.Force) / self.Mass

		acceleration = acceleration - self.Velocity * self.Damping

		self.Velocity = self.Velocity + acceleration * scaledDeltaTime
		self.Position = self.Position + self.Velocity * scaledDeltaTime
	end

	return self.Position
end

return Spring