local DataStoreService = game:GetService("DataStoreService")
local ODS = {}
ODS.__index = ODS

function ODS.new(LeaderboardName: string)
	local self = setmetatable({}, ODS)

	self._orderedDataStore = nil
	self._cachedLeaderboardData = {}
	self._leaderboardName = LeaderboardName
	self._leaderboardType = "AllTime"

	self:_setup()

	return self
end

function ODS:_setup()
	self._orderedDataStore = DataStoreService:GetOrderedDataStore(self._leaderboardName)
	self._cachedLeaderboardData = self:FetchLatest()
end

function ODS:UpdateKey(key: string, value: any)
	if not self._orderedDataStore then
		warn("OrderedDataStore not initialized")
		return
	end

	local success, err = pcall(function()
		self._orderedDataStore:SetAsync(key, math.floor(value))
	end)

	if not success then
		warn(`Leaderboard:UpdateKey() failed: {err}`)
	end
end

function ODS:FetchLatest()
	if not self._orderedDataStore then
		warn("OrderedDataStore not initialized")
		return
	end

	local success, response = pcall(function()
		return self._orderedDataStore:GetSortedAsync(false, 50)
	end)

	if success then
		local page = response:GetCurrentPage()
		local data = {}
		for index, value in page do
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

return ODS
