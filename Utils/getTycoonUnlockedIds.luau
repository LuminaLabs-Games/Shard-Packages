local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage.Packages.Data)
function getTycoonUnlockedIds(player: Player, tycoonId: string)
	local profile = Data:GetProfileAsync(player)

	if not profile then
		return
	end

	local tycoons = profile:Get("Tycoons")
	if not tycoons then
		return
	end

	local tycoon = tycoons[tycoonId]
	if not tycoon then
		return
	end

	local unlockedIds = tycoon["UnlockedIds"]
	if not unlockedIds then
		return
	end

	return unlockedIds
end

return getTycoonUnlockedIds
