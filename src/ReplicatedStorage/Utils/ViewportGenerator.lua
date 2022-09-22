--[[
	About: This module can be used to easily create viewport frames.
	
	Collaborators: DEV_Sal
--]]

-- REQUIRES --

-- VARIABLES --
--/References
local viewportTemplate = script:WaitForChild("WeaponViewport")

--/Constants
local DEFAULT_CAMERA_OFFSET = Vector3.new(2, 2, 2)

local module = {}

-- PUBLIC METHODS --

function module.SetupModel(model)
	--/Handle single part
	if model:IsA("BasePart") then
		local newModel = Instance.new("Model")
		model.Parent = newModel
		newModel.PrimaryPart = model
		model = newModel
	end

	--/Handle tool
	if model:IsA("Tool") then
		local newModel = Instance.new("Model")

		--/Move all baseparts to new model
		for _, basePart in pairs(model:GetDescendants()) do
			if basePart:IsA("BasePart") then
				basePart.Anchored = true
				basePart.Parent = newModel
			end
		end

		--/Create primary part
		local modelCFrame, modelSize = newModel:GetBoundingBox()
		local primaryPart = Instance.new("Part")
		primaryPart.Transparency = 1
		primaryPart.Anchored = true
		primaryPart.Size = modelSize
		primaryPart.CFrame = modelCFrame
		primaryPart.Parent = newModel

		newModel.PrimaryPart = primaryPart
		model = newModel
	end
	
	return model
end

function module.CreateViewport(model, cameraOffset)
	if not cameraOffset then cameraOffset = DEFAULT_CAMERA_OFFSET end
	
	local viewportClone = viewportTemplate:Clone()
	
	return module.SetViewport(model, viewportClone, cameraOffset)
end

function module.SetViewport(model, viewport, cameraOffset)
	if not cameraOffset then cameraOffset = DEFAULT_CAMERA_OFFSET end
	
	--/Make sure model is cloned
	model = model:Clone()
	
	--/Make sure model is set up correctly
	local model = module.SetupModel(model)
	
	--/Make sure contents are there
	local renderFrame = viewport:FindFirstChild("Render")
	if not renderFrame then
		warn("no render frame")
		return
	end

	--/Remove existing models from viewport if applicable
	local existingModel = renderFrame:FindFirstChild("Model")
	if existingModel then
		existingModel:Destroy()
	end
	
	--/Make sure parameter is a model
	if not model:IsA("Model") then warn("viewports need to have a model or basepart") return end
	if not model.PrimaryPart then warn("viewport models need to have a primary part") return end

	--/Set model cframe to 0
	model:SetPrimaryPartCFrame(CFrame.new())

	--/Create camera for viewport
	local viewportCamera = renderFrame:FindFirstChild("Camera") or Instance.new("Camera")
	viewportCamera.Name = "Camera"
	viewportCamera.Parent = viewport.Render
	viewport.Render.CurrentCamera = viewportCamera

	local primaryPartPosition = model:GetModelCFrame().Position
	local _, modelSize = model:GetBoundingBox()

	local cameraPosition = primaryPartPosition + cameraOffset * modelSize.Magnitude/3
	local cameraCFrame = CFrame.new(cameraPosition, primaryPartPosition)
	viewportCamera.CFrame = cameraCFrame

	model.Parent = viewport.Render

	return viewport
end

-- INITIALIZE --

return module