local RunService = game:GetService("RunService")

local Leaderboard = {}
Leaderboard.__index = Leaderboard

local IsStudio = RunService:IsStudio()

function Leaderboard.new(props: {
	LeaderboardName: string,
	LeaderboardType: "AllTime" | "Monthly" | "Weekly" | "Daily",
})
	local self = setmetatable({}, Leaderboard)

	if IsStudio then
		props.LeaderboardName = `{props.LeaderboardName}_{props.LeaderboardType}_studio`
	end

	props.LeaderboardName = `{props.LeaderboardName}_{props.LeaderboardType}`

	self.LeaderboardType = props.LeaderboardType
	self.LeaderboardName = props.LeaderboardName
	self.Extra = nil

	if self.LeaderboardType == "Monthly" or self.LeaderboardType == "Weekly" or self.LeaderboardType == "Daily" then
		self.LeaderboardType = "Expirable"
		self.Extra = props.LeaderboardType
	end

	return self:_setup()
end

function Leaderboard:_setup()
	return require(script.Components[self.LeaderboardType]).new(self.LeaderboardName, self.Extra)
end

return Leaderboard
