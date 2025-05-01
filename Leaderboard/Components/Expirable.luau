local MemoryStoreService = game:GetService("MemoryStoreService")
local Expirable = {}
Expirable.__index = Expirable

function Expirable.new(LeaderboardName: string, extras: string)
	local self = setmetatable({}, Expirable)

	self._memoryStore = MemoryStoreService:GetSortedMap(LeaderboardName) :: MemoryStoreSortedMap
	self._cachedLeaderboardData = self:FetchLatest()
	self._leaderboardName = LeaderboardName
	self._leaderboardType = extras
	self._expirationTime = 0

	if self._leaderboardType == "Monthly" then
		self._expirationTime = 2592000 -- 30 days in seconds
	elseif self._leaderboardType == "Weekly" then
		self._expirationTime = 604800 -- 7 days in seconds
	elseif self._leaderboardType == "Daily" then
		self._expirationTime = 86400 -- 1 day in seconds
	end

	return self
end

function Expirable:UpdateKey(key: string, value: any)
	if not self._memoryStore then
		return
	end

	local success, err = pcall(function()
		self._memoryStore:SetAsync(key, math.floor(value), self._expirationTime)
	end)

	if not success then
		warn(`Leaderboard:UpdateKey() failed: {err}`)
	end
end

function Expirable:FetchLatest()
	if not self._memoryStore then
		return
	end

	local success, response = pcall(function()
		return self._memoryStore:GetRangeAsync(Enum.SortDirection.Descending, 50)
	end)

	if success then
		local data = {}
		for index, value in response do
			table.insert(data, {
				Key = value.key,
				Value = value.value,
				Position = index,
			})
		end

		self._cachedLeaderboardData = data

		return data
	else
		warn(`Leaderboard:FetchLatest() failed: {response}`)
	end

	return {}
end

return Expirable
