local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local observeLocalCharacter = require(ReplicatedStorage.Packages.Observers.observeCharacter)
local Trove = require(ReplicatedStorage.Packages.Trove)

local arrowTemplate = ReplicatedStorage:WaitForChild("Objects"):WaitForChild("Effects"):WaitForChild("GuideBeam")

local CharacterGuideArrow = {}
CharacterGuideArrow.__index = CharacterGuideArrow

function CharacterGuideArrow.new()
	local self = setmetatable({}, CharacterGuideArrow)

	self._cachedTarget = nil
	self._targetTrove = Trove.new()

	self:_initialize()

	return self
end

function CharacterGuideArrow:_initialize()
	observeLocalCharacter(function(character)
		if character == nil then
			return
		end

		-- Restore the target if we had one cached
		if self._cachedTarget then
			-- Small delay to ensure character is fully loaded
			task.wait(0.1)
			self:SetTarget(self._cachedTarget)
		end

		return function()
			-- Don't clear cached target on character change, just clean up instances
			self._targetTrove:Clean()
		end
	end)
end

function CharacterGuideArrow:SetTarget(target)
	local character = Players.LocalPlayer.Character
	if not character then
		-- Cache target even if character isn't ready
		self._cachedTarget = target
		return
	end

	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	if not humanoidRootPart then
		self._cachedTarget = target
		return
	end

	self._targetTrove:Clean()

	-- Verify target still has a parent (not streamed out)
	if not target.Parent then
		self._cachedTarget = target
		return
	end

	local newArrow = arrowTemplate:Clone()
	newArrow.Parent = workspace
	self._targetTrove:Add(newArrow)

	local characterAttachment = Instance.new("Attachment")
	characterAttachment.Parent = humanoidRootPart
	self._targetTrove:Add(characterAttachment)

	local targetAttchment = Instance.new("Attachment")
	targetAttchment.Parent = target
	self._targetTrove:Add(targetAttchment)

	newArrow.Attachment0 = characterAttachment
	newArrow.Attachment1 = targetAttchment
	self._cachedTarget = target

	-- Monitor if target gets streamed out/destroyed
	local ancestryConnection
	ancestryConnection = target.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self._targetTrove:Clean()
		end
	end)
	self._targetTrove:Add(ancestryConnection)

	-- Monitor if target streams back in
	local checkConnection
	checkConnection = target.AncestryChanged:Connect(function(_, parent)
		if parent and not newArrow.Parent then
			task.wait(0.1)
			if self._cachedTarget == target then
				self:SetTarget(target)
			end
		end
	end)
	self._targetTrove:Add(checkConnection)
end

function CharacterGuideArrow:ClearTarget()
	self._targetTrove:Clean()
	self._cachedTarget = nil
end

return CharacterGuideArrow.new()
