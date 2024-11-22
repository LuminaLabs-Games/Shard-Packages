local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetRegistry = {}
AssetRegistry.__index = AssetRegistry

function AssetRegistry.new()
	local self = setmetatable({}, AssetRegistry)

	self:initialize()

	return self
end

function AssetRegistry:_hideObjects()
	local Hide = CollectionService:GetTagged("Hide")

	for _, object in Hide do
		object.Transparency = 1
		object.CanCollide = false
	end
end

function AssetRegistry:initialize()
	self:_hideObjects()
	local descendants = CollectionService:GetTagged("Object")
	local objectFolder = CollectionService:GetTagged("ObjectFolder")[1]

	for _, object in descendants do
		if not object:FindFirstAncestor("Objects") then
			object.Parent = objectFolder.Uncategorized
		end
	end

	objectFolder.Parent = ReplicatedStorage
end

return AssetRegistry
