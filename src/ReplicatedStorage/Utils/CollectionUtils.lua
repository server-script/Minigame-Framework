local CollectionUtils = {}

-- SERVICES --
local collectionService = game:GetService("CollectionService")

-- VARIABLES --
--/Public events
local taggedAddedToWorkspace = Instance.new("BindableEvent")
CollectionUtils.TaggedAddedToWorkspace = taggedAddedToWorkspace.Event
local taggedRemovedFromWorkspace = Instance.new("BindableEvent")
CollectionUtils.TaggedRemovedFromWorkspace = taggedRemovedFromWorkspace.Event

--/Holders
local tagObjectConnections = {}
local tagConnections = {}
local taggedInWorkspace = {}
local tagAddedToWorkspaceEvents = {}
local tagRemovedFromWorkspaceEvents = {}
local recordedTags = {}

local activeClasses = {}

-- PUBLIC METHOD --
function CollectionUtils.StartRecordingTag(tag)
	if tag == CollectionUtils then
		error("SOFT ERROR - Attempted to call StartRecordingTag with : instead of .")
	end
	
	if recordedTags[tag] then return end
	CollectionUtils.StopRecordingTag(tag)
	tagObjectConnections[tag] = {}
	tagConnections[tag] = {}
	taggedInWorkspace[tag] = {}
	tagAddedToWorkspaceEvents[tag] = Instance.new("BindableEvent")
	tagRemovedFromWorkspaceEvents[tag] = Instance.new("BindableEvent")
	recordedTags[tag] = true
	
	for _, tagObject in pairs(collectionService:GetTagged(tag)) do
		OnTagObjectAdded(tag, tagObject)
	end
	collectionService:GetInstanceAddedSignal(tag):Connect(function(tagObject) OnTagObjectAdded(tag, tagObject) end)
	
	collectionService:GetInstanceRemovedSignal(tag):Connect(function(tagObject) OnTagObjectRemoved(tag, tagObject) end)
end

function CollectionUtils.StopRecordingTag(tag)
	if tagConnections[tag] then
		for _, connection in pairs(tagConnections) do
			connection:Disconnect()
		end
	end
	if tagObjectConnections[tag] then
		for item, connections in pairs(tagObjectConnections) do
			for _, connection in pairs(connections) do
				connection:Disconnect()
			end
		end
	end
	tagConnections[tag] = nil
	tagObjectConnections[tag] = nil
	taggedInWorkspace[tag] = nil
	recordedTags[tag] = nil
end

function CollectionUtils.GetTaggedAddedToWorkspaceEvent(tag)
	if tagAddedToWorkspaceEvents[tag] then
		return tagAddedToWorkspaceEvents[tag].Event
	else
		warn("[COLLECTIONUTILS] Attempted to get TaggedAddedToWorkspaceEvent from an unrecorded tag", tag, ". Please use CollectionUtils.StartRecordingTag().")
	end
end

function CollectionUtils.GetTaggedRemovedFromWorkspaceEvent(tag)
	if tagRemovedFromWorkspaceEvents[tag] then
		return tagRemovedFromWorkspaceEvents[tag].Event
	else
		warn("[COLLECTIONUTILS] Attempted to get TaggedRemovedFromWorkspaceEvent from an unrecorded tag", tag, ". Please use CollectionUtils.StartRecordingTag().")
	end
end

function CollectionUtils.GetTaggedInWorkspace(tag)
	if taggedInWorkspace[tag] then
		return taggedInWorkspace[tag]
	else
		warn("[COLLECTIONUTILS] Attempted to get TaggedInWorkspace from an unrecorded tag", tag, ". Please use CollectionUtils.StartRecordingTag().")
	end
end

function CollectionUtils.PairTagWithClass(tag, constructorClass) --constructor class must be already required
	for _, ship in pairs(collectionService:GetTagged(tag)) do
		coroutine.wrap(function()
			wait()
			InitializeTagClass(ship, constructorClass)
		end)()
	end
	collectionService:GetInstanceAddedSignal(tag):Connect(function(tagged) InitializeTagClass(tagged, constructorClass) end)
	collectionService:GetInstanceRemovedSignal(tag):Connect(TerminateTagClass)
end

function CollectionUtils.TieFunctionToTagInstances(tag, callback)
	collectionService:GetInstanceAddedSignal(tag):Connect(callback)
	for _, tagged in pairs(collectionService:GetTagged(tag)) do
		task.spawn(callback, tagged)
	end
end

function CollectionUtils.TieFunctionToWorkspaceTagInstances(tag, callback)
	CollectionUtils.GetTaggedAddedToWorkspaceEvent(tag):Connect(callback)
	for _, tagged in pairs(CollectionUtils.GetTaggedInWorkspace(tag)) do
		task.spawn(callback, tagged)
	end
end

-- PRIVATE FUNCTIONS --
function OnTagObjectAdded(tag, tagObject)
	tagObjectConnections[tag][tagObject] = {}
	
	UpdateTagObjectWorkspaceStatus(tag, tagObject)
	
	local parentChangedConnection = tagObject.AncestryChanged:Connect(function()
		UpdateTagObjectWorkspaceStatus(tag, tagObject)
	end)
	table.insert(tagObjectConnections[tag][tagObject], parentChangedConnection)
end

function OnTagObjectRemoved(tag, tagObject)
	table.remove(taggedInWorkspace[tag], table.find(taggedInWorkspace[tag], tagObject))
	
	if not tagObjectConnections[tag][tagObject] then return end
	for _, connection in pairs(tagObjectConnections[tag][tagObject]) do
		connection:Disconnect()
	end
	tagObjectConnections[tag][tagObject] = nil
end

function UpdateTagObjectWorkspaceStatus(tag, tagObject)
	local isInList = table.find(taggedInWorkspace[tag], tagObject)
	if tagObject:IsDescendantOf(workspace) then
		if not isInList then
			table.insert(taggedInWorkspace[tag], tagObject)
			taggedAddedToWorkspace:Fire(tag, tagObject)
			tagAddedToWorkspaceEvents[tag]:Fire(tagObject)
		end
	else
		if isInList then
			table.remove(taggedInWorkspace[tag], isInList)
			taggedRemovedFromWorkspace:Fire(tag, tagObject)
			tagRemovedFromWorkspaceEvents[tag]:Fire(tagObject)
		end
	end
end

function InitializeTagClass(tagged, constructorClass)
	local newClassInstance = constructorClass.new(tagged)
	activeClasses[tagged] = newClassInstance
end

function TerminateTagClass(tagged)
	if activeClasses[tagged] and activeClasses[tagged].Terminate then
		activeClasses[tagged]:Terminate()
	end

	activeClasses[tagged] = nil
end

return CollectionUtils
