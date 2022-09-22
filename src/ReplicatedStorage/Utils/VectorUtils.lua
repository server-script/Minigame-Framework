-- VECTOR UTILS BY ORO --

--[[
Documentation:

So this is a singleton module containing static methods to make your life easier around vectors

Distance(Vector3 start, Vector3 target) : returns float
	Returns the distance between start and target
	
Direction(Vector3 start, Vector3 target) : returns Vector3
	Returns a unit vector pointing from start to target
	
ProjectPointOnPlane(Vector3 planePosition,Vector3 planeNormal, Vector3 point) : returns Vector3
	Returns the given point projected on the plane defined by planePosition and planeNormal
	
ProjectPointFromPlane(Vector3 planePosition,Vector3 planeNormal, Vector3 point, float distance) : returns Vector3
	Returns the point vector projected on the plane, then moves it in the planeNormal direction by distance
	
PointDistanceFromPlane( Vector3 planePosition,Vector3 planeNormal, Vector3 point) : returns float
	Returns the distance between point and the closest point on the plane
	
DirectionDistance(Vector3 start, Vector3 target, Vector3 direction) : returns float
	Returns the distance between start and target relative to the direction vector
	
DirectionLength(Vector3 vector, Vector3 direction) : returns float
	Returns the length of vector relative to the given direction

ProjectPointOnLine(Vector3 point, Vector3 LineStart, Vector3 LineEnd) : returns Vector3
	Returns the closest vector3 to point on the infinite line defined by LineStart -> LineEnd

ClampVectorOnLine(Vector3 target, Vector3 Limit1, Vector3 Limit2) : returns Vector3
	Returns the closest vector3 to point on the finite line defined by Limit1 -> Limit2

AxisAngleBetween(Vector3 from, Vector3 to, Vector3 axis) : returns float
	Returns the angle between from and to relative to the plane defined by axis (Axis is the normal of the plane)

AxisAngleBetweenNormals(Vector3 from, Vector3 to, Vector3 axis) : returns float
	Like AxisAngleBetween, except it's more efficent, but it requires from and to to be unit vectors
	
SpreadVector(Vector3 direction, float spread) : returns Vector3
	Returns the direction rotated by a random angle between 0 and spread
	
RandomPointInArea2D(float radius) : returns Vector2
	Returns a random evenly distributed point in a circle
	
RandomPointInArea3D(float radius) : returns Vector3
	Returns a random evenly distributed point in a sphere
	
RandomUnitVector2() : returns Vector2
	Returns a random evenly distributed direction on a circle
	
RandomUnitVector3() : returns Vector3
	Returns a random evenly distributed direction on a sphere

]]
local random = Random.new()

local VUtils = {}

VUtils.zero = Vector3.new()

VUtils.one = Vector3.new(1,1,1)

VUtils.forward = Vector3.new(0,0,1)

VUtils.back = Vector3.new(0,0,-1)

VUtils.up = Vector3.new(0,1,0)

VUtils.down = Vector3.new(0,-1,0)

VUtils.left = Vector3.new(-1,0,0)

VUtils.right = Vector3.new(1,0,0)

VUtils.positiveInfinity = Vector3.new(math.huge, math.huge, math.huge)

VUtils.negativeInfinity = Vector3.new(-math.huge, -math.huge, -math.huge)

VUtils.Phi = (math.sqrt(5)+1)/2

VUtils.Deg2Rad = math.pi * 2 / 360

VUtils.Rad2Deg = 1 / VUtils.Deg2Rad

function --[[Vector3]] VUtils.ProjectPointFromPlane(--[[Vector3]] planePosition,--[[Vector3]] planeNormal, --[[Vector3]] point, --[[float]] distance)
	local d = -VUtils.PointDistanceFromPlane(planePosition, planeNormal, point)
	return point + (planeNormal * d) + planeNormal * distance
end

function --[[Vector3]] VUtils.ProjectPointOnPlane( --[[Vector3]] planePosition,--[[Vector3]] planeNormal, --[[Vector3]] point)
	return point + -planeNormal * VUtils.PointDistanceFromPlane(planePosition, planeNormal, point)
end

function --[[float]] VUtils.PointDistanceFromPlane( --[[Vector3]] planePosition,--[[Vector3]] planeNormal, --[[Vector3]] point)
	return planeNormal:Dot(point - planePosition)
end

function --[[Vector3]] VUtils.Direction(--[[Vector3]] start, --[[Vector3]] target)
	local heading = target - start
	if heading == Vector3.new() then
		return Vector3.new()
	end
	return heading.Unit;
end

function VUtils.ToVector2(vector)
	return Vector2.new(vector.X, vector.Y)
end

function VUtils.ToVector3(vector, zComponent)
	return Vector3.new(vector.X, vector.Y, zComponent)
end

function VUtils.Normalize(vector)
	if vector.Magnitude < 0.0001 then
		return Vector3.new()
	end
	return vector.Unit
end

function --[[Vector3]] VUtils.XZDirection(--[[Vector3]] start, --[[Vector3]] target)
	local heading = target - start
	if heading == Vector3.new() then
		return Vector3.new()
	end
	heading = Vector3.new(heading.X, 0 , heading.Z)
	return heading.Unit;
end

function --[[Vector3]] VUtils.ToZXComponents(--[[Vector3]] vector)
	return Vector3.new(vector.X,0,vector.Z)
end

function --[[Vector3]] VUtils.SetYComponent(--[[Vector3]] vector, y)
	return Vector3.new(vector.X,y,vector.Z)
end

function --[[Vector3]] VUtils.SetXComponent(--[[Vector3]] vector, x)
	return Vector3.new(x, vector.Y,vector.Z)
end

function --[[Vector3]] VUtils.SetZComponent(--[[Vector3]] vector, z)
	return Vector3.new(vector.X,vector.Y,z)
end


function --[[float]] VUtils.Distance(--[[Vector3]] start, --[[Vector3]] target)
	local heading = target - start;
	return heading.Magnitude;
end

function --[[float]] VUtils.XZDistance(--[[Vector3]] start, --[[Vector3]] target)
	local heading = target - start
	if heading == Vector3.new() then
		return 0
	end
	heading = Vector3.new(heading.X, 0 , heading.Z)
	return heading.Magnitude;
end

function --[[float]] VUtils.DirectionDistance(--[[Vector3]] start, --[[Vector3]] target, --[[Vector3]] direction)
	return math.abs(VUtils.PointDistanceFromPlane(direction, start, target));
end

function VUtils.SqrMagnitude(vector)
	return vector.X * vector.X + vector.Y * vector.Y + vector.Z * vector.Z
end

function VUtils.SqrMagnitude2D(vector)
	return vector.X * vector.X + vector.Y * vector.Y
end

function --[[float]] VUtils.DirectionLength(--[[Vector3]] vector, --[[Vector3]] direction)
	return math.abs(VUtils.PointDistanceFromPlane(Vector3.new(), direction, vector));
end

function --[[float]] VUtils.SignedDirectionLength(--[[Vector3]] vector, --[[Vector3]] direction)
	return VUtils.PointDistanceFromPlane(Vector3.new(), direction, vector);
end

function --[[Vector3]] VUtils.ClampVectorOnLine(--[[Vector3]] target, --[[Vector3]] Limit1, --[[Vector3]] Limit2)
	local projection = VUtils.ProjectPointOnLine(target, Limit1, Limit2)
	local maxDistance = VUtils.Distance(Limit1, Limit2)
	if VUtils.Distance(Limit1, projection) > maxDistance then
		return Limit2;
	end
	if VUtils.Distance(Limit2,projection) > maxDistance then
		return Limit1;
	end
			
	return projection;
end

function --[[Vector3]] VUtils.ProjectPointOnLine(--[[Vector3]] point, --[[Vector3]] LineStart, --[[Vector3]] LineEnd)
	local AP = point - LineStart
	local AB = LineEnd - LineStart
	return LineStart + AP:Dot(AB) / AB:Dot(AB) * AB
end

function --[[Vector3]] VUtils.SpreadVector(--[[Vector3]]direction, --[[float]]spread, random)
	if not random then
		random = Random.new()
	end
	
	local deflection = random:NextNumber(0, spread)
	local cf = CFrame.new(Vector3.new(), direction)
	cf = cf*CFrame.Angles(0, 0, random:NextNumber(0,2*math.pi))
	cf = cf*CFrame.Angles(deflection, 0, 0)
	return cf.lookVector
end

function --[[Vector3]] VUtils.RandomPointInArea2D(--[[float]]radius)
	local t = 2 * math.pi * math.random()
	local u = math.random()+math.random()
	local r
	if u>1 then 
		r = 2-u 
	else 
		r = u
	end
	return Vector2.new(r* math.cos(t) * radius, r* math.sin(t) * radius)
end

function --[[Vector3]] VUtils.RandomUnitVector2()
	return VUtils.RandomPointInArea2D(1).Unit
end

function --[[Vector3]] VUtils.RandomPointInArea3D(--[[float]]radius)
	local rand = Random.new()
	local vec
	local attempts = 1000
	while attempts > 0 do
		vec = Vector3.new(rand:NextNumber(-1,1), rand:NextNumber(-1,1), rand:NextNumber(-1,1))
		if vec.Magnitude <= 1 then
			return vec
		end
		attempts = attempts - 1
	end
	
	return vec * radius
end

function --[[Vector3]] VUtils.RandomUnitVector3()
	return VUtils.RandomPointInArea3D(1).Unit
end

function VUtils.GetRandomicPerpendicularVector(heading, random)
	local random = random or Random.new()

	local randomVector
	repeat randomVector = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-1,1), random:NextNumber(-1,1)) until randomVector ~= Vector3.new() and randomVector~= heading
	local perpendicularRandomDirection = heading:Cross(randomVector).Unit

	return perpendicularRandomDirection
end

function VUtils.GetRandomicPerpendicularVectorBetween(origin, target, random)
	local heading = target - origin
	local random = random or Random.new()
	
	local randomVector
	
	repeat randomVector = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-1,1), random:NextNumber(-1,1)) until randomVector ~= Vector3.new() and randomVector~= heading
	local perpendicularRandomDirection = heading:Cross(randomVector).Unit
	
	
	return perpendicularRandomDirection
end

-- Returns n 2D points evenly distributed in a circle of radius "radius" at alpha 0
-- Making alpha higher makes points distribute closer to the border.
-- This method is most beautiful
function VUtils.Sunflower(n, alpha, radius)
	local Positions = {}
	local b = math.round(alpha*math.sqrt(n))
	local phi = VUtils.Phi
	for k=1, n do
		local r
		if k > n-b then
			r = 1
		else
			r = math.sqrt(k-1/2)/math.sqrt(n-(b+1)/2)
		end
		local theta = 2*math.pi*k/phi^2
		table.insert(Positions,Vector2.new(r*math.cos(theta), r*math.sin(theta)) * radius)
	end
	return Positions
end

function VUtils.CFrameFromUpVector3(upVector)
	local rightVector = VUtils.GetRandomicPerpendicularVectorBetween(Vector3.new(), upVector)
	local lookVector = upVector:Cross(rightVector)
	
	return CFrame.fromMatrix(Vector3.new(), rightVector, upVector, lookVector)
end

function VUtils.CFrameFromForwardVector3(lookVector)
	local rightVector = VUtils.GetRandomicPerpendicularVectorBetween(Vector3.new(), lookVector)
	local upVector = lookVector:Cross(rightVector)
	
	return CFrame.fromMatrix(Vector3.new(), rightVector, upVector, lookVector)
end

function VUtils.CFrameFromForwardUpVector3(lookVector, upVector)
	local rightVector = lookVector:Cross(upVector)
	
	return CFrame.fromMatrix(Vector3.new(), rightVector, upVector, -lookVector)
end

function VUtils.CFrameFromRightVector3(rightVector)
	local upVector = VUtils.GetRandomicPerpendicularVectorBetween(Vector3.new(), rightVector)
	local lookVector = -upVector:Cross(rightVector)
	
	return CFrame.fromMatrix(Vector3.new(), rightVector, upVector, lookVector)
end

function VUtils.FindPlaneLineIntersection(origin, target, planePosition, planeNormal)
	local epsilon = .000001
	
	local u = target - origin
	local dot = planeNormal:Dot(u)
	
	if math.abs(dot) > epsilon then
		
		local w = origin - planePosition
		local fac = -planeNormal:Dot(w) / dot
		local u = u * fac
		return origin + u
	else
		return nil
	end
end

function VUtils.MoveTowards(current, target, maxDistanceDelta)
	local toVector_x = target.x - current.x
	local toVector_y = target.y - current.y
	local toVector_z = target.z - current.z

	local sqdist = toVector_x * toVector_x + toVector_y * toVector_y + toVector_z * toVector_z

	if sqdist == 0 or (maxDistanceDelta >= 0 and sqdist <= maxDistanceDelta * maxDistanceDelta) then
		return target
	end
	
	local dist = math.sqrt(sqdist)

	return Vector3.new(current.x + toVector_x / dist * maxDistanceDelta,
		current.y + toVector_y / dist * maxDistanceDelta,
		current.z + toVector_z / dist * maxDistanceDelta)
end

function VUtils.SmoothDamp(current, target, currentVelocity, smoothTime, maxSpeed, deltaTime)
	local output_x = 0
	local output_y = 0
	local output_z = 0
	
	smoothTime = math.max(0.0001, smoothTime)
	local omega = 2 / smoothTime
	
	local x = omega * deltaTime
	local exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
	
	local change_x = current.X - target.X
	local change_y = current.Y - target.Y
	local change_z = current.Z - target.Z
	local originalTo = target
	
	-- Clamp maximum speed
	local maxChange = maxSpeed * smoothTime
	
	local maxChangeSq = maxChange * maxChange
	local sqrmag = change_x * change_x + change_y * change_y + change_z * change_z
	if sqrmag > maxChangeSq then
		local mag = math.sqrt(sqrmag)
		change_x = change_x / mag * maxChange
		change_y = change_y / mag * maxChange
		change_z = change_z / mag * maxChange
	end
		
	target = Vector3.new(current.x - change_x, current.y - change_y, current.z - change_z)
	
	local temp_x = (currentVelocity.X + omega * change_x) * deltaTime;
	local temp_y = (currentVelocity.Y + omega * change_y) * deltaTime;
	local temp_z = (currentVelocity.Z + omega * change_z) * deltaTime;
	
	currentVelocity = Vector3.new((currentVelocity.x - omega * temp_x) * exp,(currentVelocity.y - omega * temp_y) * exp, (currentVelocity.z - omega * temp_z) * exp)
	
	output_x = target.X + (change_x + temp_x) * exp
	output_y = target.Y + (change_y + temp_y) * exp
	output_z = target.Z + (change_z + temp_z) * exp
	
	-- Prevent overshooting
	local origMinusCurrent_x = originalTo.X - current.X
	local origMinusCurrent_y = originalTo.Y - current.Y
	local origMinusCurrent_z = originalTo.Z - current.Z
	local outMinusOrig_x = output_x - originalTo.X
	local outMinusOrig_y = output_y - originalTo.Y
	local outMinusOrig_z = output_z - originalTo.Z
	
	if origMinusCurrent_x * outMinusOrig_x + origMinusCurrent_y * outMinusOrig_y + origMinusCurrent_z * outMinusOrig_z > 0 then
		output_x = originalTo.X;
		output_y = originalTo.Y;
		output_z = originalTo.Z;
			
		currentVelocity = Vector3.new((output_x - originalTo.x) / deltaTime,(output_y - originalTo.y) / deltaTime,(output_z - originalTo.z) / deltaTime)
	end
	
	return Vector3.new(output_x, output_y, output_z), currentVelocity
end

function VUtils.SmoothTremble(currentShake, currentVelocity, shakeTarget, lastShakeRecorded, maxShake, deltaTime)
	if time() - lastShakeRecorded > .06 then
		lastShakeRecorded = time()
		shakeTarget = VUtils.RandomPointInArea3D(1) * maxShake
	end
	currentShake, currentVelocity = VUtils.SmoothDamp(currentShake, shakeTarget, currentVelocity, 0.05, math.huge, deltaTime)
	return currentShake, currentVelocity, shakeTarget
end

function VUtils.ClampMagnitude(vector, maxMagnitude)
	return (vector.Magnitude > maxMagnitude and (vector.Unit * maxMagnitude) or vector)
end


function VUtils.AngleBetween(vector1, vector2)
	return math.acos(math.clamp(vector1.Unit:Dot(vector2.Unit), -1, 1))
end


function VUtils.AngleBetweenSigned(vector1, vector2, axisVector)
	local angle = VUtils.AngleBetween(vector1, vector2)
	local sign = math.sign(axisVector:Dot(vector1:Cross(vector2)))
	if sign == 0 then sign = 1 end
	return angle * sign
end

function VUtils.RotateVector3D(Vector, Radians, Axis)
	return CFrame.fromAxisAngle(Axis, Radians):VectorToWorldSpace(Vector)
end

function VUtils.RotateVectorTowards(StartVector, EndVector, angle)
	local dPrime = StartVector:Cross(EndVector):Cross(StartVector).Unit
	return math.cos(angle)*StartVector + math.sin(angle)*dPrime;
end

function VUtils.Reflect(inDirection, inNormal)
	local factor = -2 * inNormal:Dot(inDirection)
	return Vector3.new(factor * inNormal.X + inDirection.X, factor * inNormal.Y + inDirection.Y, factor * inNormal.Z + inDirection.Z);
end

--Point is in Oriented Bounding Box (3D), optimized to its maximum potential
function VUtils.PointIsInOBB(position, boxCFrame, boxSize)
	local relativePos = boxCFrame:PointToObjectSpace(position)
	local halfSize = boxSize/2
	return math.abs(relativePos.X) < halfSize.X and math.abs(relativePos.Y) < halfSize.Y and math.abs(relativePos.Z) < halfSize.Z
end

--Point is in Axis Aligned Bounding Box (3D), optimized to its maximum potential
function VUtils.PointIsInAABB(position, boxPosition, boxSize)
	local relativePos = boxPosition-position
	local halfSize = boxSize/2
	return math.abs(relativePos.X) < halfSize.X and math.abs(relativePos.Y) < halfSize.Y and math.abs(relativePos.Z) < halfSize.Z
end

--Relative height is the highest point that the thrown object will reach compared to its position. Make sure it's higher than targetPosition or the equation is impossible
function VUtils.KinematicVelocityToTarget(originPosition, targetPosition, relativeHeight, gravity)
	local YDistance = targetPosition.Y - originPosition.Y
	local XZDistance = Vector2.new(targetPosition.X - originPosition.X, targetPosition.Z - originPosition.Z)
	
	local YVelocity = math.sqrt(-2*gravity*relativeHeight)
	warn(YVelocity)
	local XZVelocity = XZDistance / (math.sqrt(-2*relativeHeight/gravity) + math.sqrt(2*(YDistance-relativeHeight)/gravity))
	
	return Vector3.new(XZVelocity.X, YVelocity, XZVelocity.Y) * -math.sign(gravity)
end

function VUtils.ClampedKinematicVelocityToTarget(originPosition, targetPosition, extraHeight, gravity)
	local YDistance = targetPosition.Y - originPosition.Y
	local XZDistance = Vector2.new(targetPosition.X - originPosition.X, targetPosition.Z - originPosition.Z)

	extraHeight = math.max(extraHeight, YDistance) + extraHeight

	local YVelocity = math.sqrt(-2*gravity*extraHeight)
	local XZVelocity = XZDistance / (math.sqrt(-2*extraHeight/gravity) + math.sqrt(2*(YDistance-extraHeight)/gravity))

	return Vector3.new(XZVelocity.X, YVelocity, XZVelocity.Y) * -math.sign(gravity)
end

function VUtils.CalculateTrajectory(initialPosition, initialVelocity, raycastParams, maxLength, frameRate, gravity, checkRate)
	gravity = gravity or Vector3.new(0, -workspace.Gravity, 0)
	frameRate = frameRate or 60
	maxLength = maxLength or 800
	checkRate = checkRate or 3

	--calculate the positions
	local positions = {initialPosition}
	local currentPosition = initialPosition
	local currentVelocity = initialVelocity
	local currentLength = 0

	local lastCheckIndex = 1
	local checkCount = 0

	local deltaTime = 1/frameRate

	local completed = false
	while true do
		currentVelocity += gravity*deltaTime
		local movement = currentVelocity*deltaTime
		local newPosition = currentPosition + movement

		table.insert(positions, newPosition)

		--check for obstacles
		checkCount+=1
		if checkCount >= checkRate then
			checkCount = 0

			local origin = positions[lastCheckIndex]
			local rayResult = workspace:Raycast(origin, newPosition-origin, raycastParams)
			if rayResult and rayResult.Instance then
				for i = 1, checkRate do
					local origin = positions[lastCheckIndex+(i-1)]
					local target = positions[lastCheckIndex+i]
					local rayResult = workspace:Raycast(origin, target-origin, raycastParams)
					if rayResult then
						for l = #positions, 1, -1 do
							currentLength -= VUtils.Distance(positions[l], positions[l]-1)
							if l == lastCheckIndex+i then 
								currentLength += VUtils.Distance(positions[l], rayResult.Position)
								break 
							else
								table.remove(positions, l)
							end
						end

						positions[lastCheckIndex+i] = rayResult.Position
						break
					end
				end
				completed = true
			else
				lastCheckIndex = #positions
			end
		end
		--

		if completed then break end
		currentLength+= movement.Magnitude
		if currentLength >= maxLength then
			break
		end
		currentPosition = newPosition
	end
	
	return positions, currentLength
end

function VUtils.GetCameraAdjustedAttackDirection(camera, rootPart, humanoid, horizontalFactor, verticalFactor)
	local cameraLook = workspace.CurrentCamera.CFrame.LookVector
	local point = rootPart.Position + humanoid.CameraOffset + cameraLook * 100
	local distance = (rootPart.Position - point).magnitude
	local difference = rootPart.CFrame.Y - point.Y

	return (rootPart.CFrame * CFrame.Angles(
		-( math.atan(difference / distance) * verticalFactor), 
		(((rootPart.Position - point).Unit):Cross(rootPart.CFrame.LookVector)).Y * horizontalFactor,
		0
		)).LookVector
end

--Given a 3D position, it returns the screen position of the object as an indicator position, meaning it will respect padding
--around the screen and when possible, return the position and rotation of an arrow pointing at the object , assuming the
--arrow image points to the right
function VUtils.WorldPositionToIndicator2D(worldPosition, screenPadding, arrowDistance)
	local camera = workspace.CurrentCamera
	local screenMin = Vector2.new(screenPadding, screenPadding)
	local screenMax = camera.ViewportSize - screenMin
	local screenCenter = camera.ViewportSize/2
	local screenPosition = camera:WorldToViewportPoint(worldPosition)
	local arrowAngle
	local relativeDirection
	if screenPosition.X > screenMax.X or screenPosition.X < screenMin.X or screenPosition.Y > screenMax.Y or screenPosition.Y < screenMin.Y or screenPosition.Z < 0 then
		local heading = camera.CFrame:VectorToObjectSpace(worldPosition - camera.CFrame.Position).Unit
		relativeDirection = Vector2.new(heading.X, heading.Y).Unit
		if relativeDirection == Vector2.new() then
			relativeDirection = Vector2.new(0,1)
		end

		-- calculate arrow rotation
		arrowAngle = VUtils.AngleBetweenSigned(Vector3.new(1, 0, 0), VUtils.ToVector3(relativeDirection, 0), Vector3.new(0,0,-1))
		--

		-- calculate pointer position
		local halfYSize = screenMax.Y/2
		local extent = relativeDirection * screenMax.Magnitude/2
		local targetOffset
		if math.abs(extent.Y) > halfYSize then
			targetOffset = (relativeDirection * math.abs(halfYSize/relativeDirection.Y))			
		else
			local halfXSize = screenMax.X/2
			targetOffset = (relativeDirection * math.abs(halfXSize/relativeDirection.X))
		end
		targetOffset = Vector2.new(targetOffset.X, -targetOffset.Y)
		screenPosition = screenCenter + targetOffset
		--

	end
	screenPosition = Vector2.new(
		math.clamp(screenPosition.X, screenMin.X, screenMax.X),
		math.clamp(screenPosition.Y, screenMin.Y, screenMax.Y)
	)

	local pointerPosition = UDim2.new(0, screenPosition.X, 0, screenPosition.Y)

	if relativeDirection then
		relativeDirection = Vector2.new(relativeDirection.X, -relativeDirection.Y)
		local arrowVectorPosition = screenPosition + relativeDirection*arrowDistance
		local arrowPosition = UDim2.new(0, arrowVectorPosition.X, 0, arrowVectorPosition.Y)
		local arrowRotation = math.deg(arrowAngle)

		return pointerPosition, arrowPosition, arrowRotation
	end

	return pointerPosition
end

function VUtils.GetRandomPointInSquare(squarePosition, SquareSizeX, SquareSizeZ)
	local halfSize = Vector2.new(SquareSizeX, SquareSizeZ) / 2
	local minX = squarePosition.X - halfSize.X
	local maxX = squarePosition.X + halfSize.X
	local minZ = squarePosition.Z - halfSize.Y
	local maxZ = squarePosition.Z + halfSize.Y
	
	return Vector3.new(random:NextNumber(minX, maxX), squarePosition.Y, random:NextNumber(minZ, maxZ))
end

function VUtils.GetSlopeDirection(SlopeNormal)
	local gravityDirection = Vector3.new(0,1,0)
	if gravityDirection == SlopeNormal or SlopeNormal == Vector3.new() then return Vector3.new() end
	
	local lateralSlope = gravityDirection:Cross(SlopeNormal)
	return lateralSlope:Cross(SlopeNormal)
end

function VUtils.VectorToAngle(vector)
	return Vector3.new( CFrame.new(Vector3.new(), vector):ToEulerAnglesYXZ() )
end

function VUtils.VectorIsBetween(vector, origin, target)
	local targetDistance = VUtils.Distance(origin, target)
	return math.abs((VUtils.Distance(vector, origin) + VUtils.Distance(vector, target)) - targetDistance) < .1
end

function VUtils.IntersectionPointsOnCircle2D(origin, target, center, radius) 
	local dp = Vector3.new(target.X - origin.X, 0, target.Z - origin.Z)
	local sect = {} --Vector3[] sect
	local a, b, c
	local bb4ac
	local mu1
	local mu2

	--  get the distance between X and Z on the segment
	--  I don't get the math here
	a = dp.X * dp.X + dp.Z * dp.Z
	b = 2 * (dp.X * (origin.X - center.X) + dp.Z * (origin.Z - center.Z))
	c = center.X* center.X + center.Z * center.Z
	c += origin.X * origin.X + origin.Z * origin.Z
	c -= 2 * (center.X * origin.X + center.Z * origin.Z)
	c -= radius * radius
	bb4ac  = b * b - 4 * a * c
	if math.abs(a) < 0.00000001 or bb4ac < 0  then
		warn("No interception")
		--  line does not intersect
		return nil
	end
	mu1 = (-b + math.sqrt(bb4ac)) / (2 * a)
	mu2 = (-b - math.sqrt(bb4ac)) / (2 * a)
	local intersectionA = Vector3.new(origin.X + mu1 * (target.X - origin.X), center.Y, origin.Z + mu1 * (target.Z - origin.Z))
	local intersectionB = Vector3.new(origin.X + mu2 * (target.X - origin.X), center.Y, origin.Z + mu2 * (target.Z - origin.Z))
	
	if VUtils.VectorIsBetween(intersectionA, origin, target) then
		table.insert(sect, intersectionA)
	end
	if VUtils.VectorIsBetween(intersectionB, origin, target) then
		table.insert(sect, intersectionB)
	end
	
	if #sect == 0 then return nil end
	
	return sect
end

function VUtils.EllipseLineInterception2D(ellipseWidth,ellipseHeight,ellipsePosition,pt1,pt2)
	local ellipseRight = ellipsePosition.X + (ellipseWidth /2)
	local ellipseTop = ellipsePosition.Y - (ellipseHeight /2)
	local ellipseLeft = ellipsePosition.X - (ellipseWidth /2)
	local ellipseDown = ellipsePosition.Y + (ellipseHeight /2)

	local c = Vector2.new(ellipseLeft + ellipseWidth / 2, ellipseTop + ellipseHeight / 2)
	ellipsePosition -= c
	pt1 -= c
	pt2 -= c

	local a = ellipseWidth / 2
	local b = ellipseHeight / 2

	local pt2Xminpt1X = pt2.X - pt1.X
	local pt2Yminpt1Y = pt2.Y - pt1.Y

	local A = (pt2.X - pt1.X) * (pt2Xminpt1X) / a / a + (pt2.Y - pt1.Y) * (pt2.Y - pt1.Y) / b / b;
	local B = 2 * pt1.X * (pt2Xminpt1X) / a / a + 2 * pt1.Y * (pt2Yminpt1Y) / b / b;
	local C = pt1.X * pt1.X / a / a + pt1.Y * pt1.Y / b / b - 1;

	local t_values = {}

	local discriminant = B * B - 4 * A * C;
	if discriminant == 0 then
		table.insert(t_values, -B / 2 / A )
	elseif discriminant > 0 then
		table.insert(t_values, (-B + math.sqrt(discriminant)) / 2 / A)
		table.insert(t_values, (-B - math.sqrt(discriminant)) / 2 / A)
	end

	local points = {}
	for _, t in ipairs(t_values) do
		if t >= 0 and t <= 1 then
			local x = pt1.X + (pt2Xminpt1X) * t + c.X
			local y = pt1.Y + (pt2Yminpt1Y) * t + c.Y
			table.insert(points, Vector2.new(x,y))
		end
	end

	return points
end

function VUtils.InfiniteLineSphereIntersection(lineStart, lineEnd, spherePosition, sphereRadius)
	local A, B, C, r = lineStart, lineEnd, spherePosition, sphereRadius

	local BxMinusAx = B.X-A.X
	local ByMinusAy = B.Y-A.Y
	local BzMinusAz = B.Z-A.Z

	local AxMinusCx = A.X-C.X
	local AyMinusCy = A.Y-C.Y
	local AzMinusCz = A.Z-C.Z

	local function Parametize(d)
		local x = A.X + d*(BxMinusAx)
		local y = A.Y + d*(ByMinusAy)
		local z = A.Z + d*(BzMinusAz)
		return Vector3.new(x,y,z)
	end

	local a = BxMinusAx*BxMinusAx + ByMinusAy*ByMinusAy + BzMinusAz*BzMinusAz
	local b = 2*(BxMinusAx*AxMinusCx + ByMinusAy*AyMinusCy + BzMinusAz*AzMinusCz)
	local c = AxMinusCx*AxMinusCx + AyMinusCy*AyMinusCy + AzMinusCz*AzMinusCz - r*r

	local delta = b*b-4*a*c

	if delta < 0 then
		return nil
	elseif delta == 0 then
		return Parametize(-b/2*a)
	elseif delta > 0 then
		local a2 = 2*a
		return Parametize((-b-math.sqrt(delta))/a2), Parametize((-b+math.sqrt(delta))/a2)
	end
end

function VUtils.InfiniteLineLineIntersection(line1Point1, line1Point2, line2Point1, line2Point2)
	local epsilon = 0.000001

	local p1,p2,p3,p4 = line1Point1, line1Point2, line2Point1, line2Point2
	local p13 = p1 - p3
	local p43 = p4 - p3

	if VUtils.SqrMagnitude(p43) < epsilon then
		return nil
	end
	local p21 = p2 - p1
	if VUtils.SqrMagnitude(p21) < epsilon then
		return nil
	end

	local d1343 = p13:Dot(p43)
	local d4321 = p43:Dot(p21)
	local d1321 = p13:Dot(p21)
	local d4343 = p43:Dot(p43)
	local d2121 = p21:Dot(p21)

	local denom = d2121 * d4343 - d4321 * d4321;
	if (math.abs(denom) < epsilon) then
		return nil
	end
	local numer = d1343 * d4321 - d1321 * d4343;

	local mua = numer / denom;
	local mub = (d1343 + d4321 * (mua)) / d4343;

	local resultSegmentPoint1 = Vector3.new(
		p1.X + mua * p21.X,
		p1.Y + mua * p21.Y,
		p1.Z + mua * p21.Z
	)
	local resultSegmentPoint2 = Vector3.new(
		p3.X + mub * p43.X,
		p3.Y + mub * p43.Y,
		p3.Z + mub * p43.Z
	)

	return resultSegmentPoint1, resultSegmentPoint2
end


function VUtils.GetPartBoundsInSlash(startHitboxCFrame, endHitboxCFrame, hitboxSize, segmentationCount, overlapParams: OverlapParams)
	local hitParts = {}
	local newIgnoreList = {}
	for _, item in pairs(overlapParams.FilterDescendantsInstances) do
		table.insert(newIgnoreList, item)
	end

	local halfHitbox = hitboxSize.Y/2
	local upperPointStart = startHitboxCFrame.Position + startHitboxCFrame.UpVector*(halfHitbox)
	local upperPointEnd = endHitboxCFrame.Position + endHitboxCFrame.UpVector*(halfHitbox)
	local segmentLength = hitboxSize.Y/segmentationCount

	local baseUpVector = (startHitboxCFrame.UpVector + endHitboxCFrame.UpVector).Unit

	for i = 1, segmentationCount do
		local segmentIndex = i-1+.5
		local startPoint = (upperPointStart-startHitboxCFrame.UpVector*(segmentLength*segmentIndex))
		local endPoint = (upperPointEnd-endHitboxCFrame.UpVector*(segmentLength*segmentIndex))

		local newOverlap = OverlapParams.new()
		newOverlap.FilterDescendantsInstances = newIgnoreList
		newOverlap.FilterType = overlapParams.FilterType
		newOverlap.CollisionGroup = overlapParams.CollisionGroup

		local lookVector = VUtils.Direction(startPoint, endPoint)
		local upVector = lookVector:Cross(baseUpVector).Unit:Cross(lookVector)
		local orientationCFrame = VUtils.CFrameFromForwardUpVector3(lookVector, upVector)
		local checkCFrame = CFrame.new((startPoint + endPoint)/2)*orientationCFrame
		local checkSize = Vector3.new(hitboxSize.X, segmentLength, VUtils.Distance(startPoint, endPoint))
		
		-- DEBUG
		--local newPart = Instance.new("Part")
		--newPart.CFrame = checkCFrame
		--newPart.Size = checkSize
		--newPart.CanCollide = false
		--newPart.CanTouch = false
		--newPart.CanQuery = false
		--newPart.Anchored = true
		--newPart.Color = Color3.new(1, 0.219608, 0.164706)
		--newPart.Material = Enum.Material.ForceField
		--newPart.Parent = workspace:FindFirstChild("Ignore") or workspace
		--coroutine.wrap(function()
		--	task.wait(1.5)
		--	game:GetService("TweenService"):Create(newPart, TweenInfo.new(1.5), {Transparency = 1}):Play()
		--	task.wait(1.5)
		--	newPart:Destroy()
		--end)()
		--

		local segmentHitParts = workspace:GetPartBoundsInBox(checkCFrame, checkSize, newOverlap)
		for _, part in pairs(segmentHitParts) do
			table.insert(hitParts, part)
			if newOverlap.FilterType == Enum.RaycastFilterType.Blacklist then
				table.insert(newIgnoreList, part)
			else
				table.remove(newIgnoreList, table.find(newIgnoreList, part))
			end
		end
	end

	return hitParts
end

--Polygon is an array of vector2
function VUtils.IsPointInPolygon2D(p, polygon )
	local inside = false;
	local j = #polygon
	for i = 1, #polygon do
		if  (polygon[i].Y > p.Y) ~= (polygon[j].Y > p.Y) and p.X < (polygon[j].X - polygon[i].X) * (p.Y - polygon[i].Y) / (polygon[j].Y - polygon[i].Y ) + polygon[i].X  then
			inside = not inside
		end
		j = i
	end

	return inside;
end

-- Returns array of vector2
function VUtils.GenerateRegularPolygon2D(position, nVertices, radius, rotationOffset)
	rotationOffset = rotationOffset or 0
	local vertices = {}
	for i = 1, nVertices do
		vertices[i] = Vector2.new(position.X + radius * math.cos((2 * math.pi * i / nVertices)+ math.rad(rotationOffset)), position.Y + radius * math.sin((2 * math.pi * i / nVertices)+ math.rad(rotationOffset)))
	end
	vertices[nVertices+1] = vertices[1]
	return vertices
end

function VUtils.GetProjectilesIntersectionPoint(shooterPosition, shooterVelocity,shotSpeed,targetPosition,targetVelocity)
	local targetRelativePosition = targetPosition - shooterPosition
	local targetRelativeVelocity = targetVelocity - shooterVelocity
	local t = FirstOrderInterceptTime(shotSpeed,targetRelativePosition,targetRelativeVelocity)
	return targetPosition + t*(targetRelativeVelocity)
end
function FirstOrderInterceptTime(shotSpeed,targetRelativePosition,targetRelativeVelocity)
	local velocitySquared = VUtils.SqrMagnitude(targetRelativeVelocity)
	if velocitySquared < 0.001 then
		return 0
	end

	local a = velocitySquared - shotSpeed*shotSpeed

	if math.abs(a) < 0.001 then
		local t = -VUtils.SqrMagnitude(targetRelativePosition)/(2*targetRelativeVelocity:Dot(targetRelativePosition))
		return math.max(t, 0) -- one cannot shoot behind in time
	end

	local b = 2*targetRelativeVelocity:Dot(targetRelativePosition)
	local c = VUtils.SqrMagnitude(targetRelativePosition)
	local determinant = b*b - 4*a*c

	if determinant > 0 then
		local t1 = (-b + math.sqrt(determinant))/(2*a)
		local t2 = (-b - math.sqrt(determinant))/(2*a)
		if t1 > 0 then
			if t2 > 0 then
				return math.min(t1, t2)
			else
				return t1
			end
		else
			return math.max(t2, 0)
		end
	elseif determinant < 0 then
		return 0
	else 
		return math.max(-b/(2*a), 0)
	end
end

function VUtils.PoissonDiskSampling2D(bottomLeft, topRight, minimumDistance, iterationPerPoint)
	local function GetSettings(bl, tr, min, iteration)
		local dimension = tr - bl
		local cell = min * 0.70710678118

		return {
			BottomLeft = bl,
			TopRight = tr,
			Center = (bl + tr) * .5,
			Dimension = Rect.new(bl, tr),

			MinimumDistance = min,
			IterationPerPoint = iteration,

			CellSize = cell,
			GridWidth = math.ceil(dimension.X / cell),
			GridHeight = math.ceil(dimension.Y / cell)
		}
	end

	local settings = GetSettings(
		bottomLeft,
		topRight,
		minimumDistance,
		iterationPerPoint
	)

	local grid = {}
	for i=1, settings.GridWidth+1 do
		grid[i] = {}
	end

	local bags = {
		Grid = grid,
		SamplePoints = {},
		ActivePoints = {}
	}

	local first = Vector2.new(random:NextNumber(settings.BottomLeft.X, settings.TopRight.X), random:NextNumber(settings.BottomLeft.Y, settings.TopRight.Y))
	local index = GetGridIndex(first, settings)
	bags.Grid[index.X][index.Y] = first
	table.insert(bags.SamplePoints, first)
	table.insert(bags.ActivePoints, first)

	repeat
		local index = random:NextInteger(1, #bags.ActivePoints)

		local point = bags.ActivePoints[index]

		local found = false;
		for k = 1, settings.IterationPerPoint do
			found = GetNextPoint(point, settings, bags)
			if found then break end
		end

		if not found then
			table.remove(bags.ActivePoints, index)
		end
	until #bags.ActivePoints == 0

	return bags.SamplePoints
end
function GetNextPoint(point, set, bags)
	local function GetRandPosInCircle(fieldMin, fieldMax)
		local theta = random:NextNumber(0, math.pi * 2)
		local radius = math.sqrt(random:NextNumber(fieldMin * fieldMin, fieldMax * fieldMax))

		return Vector2.new(radius * math.cos(theta), radius * math.sin(theta))
	end

	local function RectContains(rect, point)
		return 
			point.X > rect.Min.X and 
			point.X < rect.Max.X and 
			point.Y > rect.Min.Y and 
			point.Y < rect.Max.Y
	end

	local found = false;
	local p = GetRandPosInCircle(set.MinimumDistance, 2 * set.MinimumDistance) + point;

	if not RectContains(set.Dimension, p) then
		return false
	end

	local minimum = set.MinimumDistance * set.MinimumDistance
	local index = GetGridIndex(p, set)
	local drop = false

	local around = 2;
	local fieldMin = Vector2.new(math.max(1, index.X - around), math.max(1, index.Y - around))
	local fieldMax = Vector2.new(math.min(set.GridWidth, index.X + around), math.min(set.GridHeight, index.Y + around))

	for i = fieldMin.X, fieldMax.X do
		if drop then break end
		for j = fieldMin.Y, fieldMax.Y do
			local q = bags.Grid[i][j]
			if q and VUtils.SqrMagnitude2D(q - p) <= minimum then
				drop = true
				break
			end
		end
	end

	if drop == false then
		found = true;

		table.insert(bags.SamplePoints, p)
		table.insert(bags.ActivePoints, p)
		bags.Grid[index.X][index.Y] = p
	end

	return found
end
function GetGridIndex(point, set)
	return Vector2.new(
		math.floor((point.X - set.BottomLeft.X) / set.CellSize) + 1,
		math.floor((point.Y - set.BottomLeft.Y) / set.CellSize) + 1
	)
end

return VUtils
