local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(script.FreecamConfig)
local freecamScript = script.Freecam

local Freecam = {}

function Freecam.checkAndInstall()
	local function ShouldAddFreeCam(player)
		if RunService:IsStudio() then
			return true
		end
		if player.UserId <= 0 then
			return true
		end

		local ALLOWED_GROUP = Config.ALLOWED_GROUPS
		for groupId, ranks in ALLOWED_GROUP do
			local inGroupSuccess, inGroup = pcall(player.IsInGroup, player, groupId)
			if inGroupSuccess and inGroup then
				local playerRankSuccess, playerRank = pcall(player.GetRankInGroup, player, groupId)
				if not playerRankSuccess then
					return false
				end
				for _, rank in ranks do
					if playerRank >= rank then
						return true
					end
				end
			end
		end

		local ALLOWED_USERS = Config.ALLOWED_USERS
		for _, userId in ALLOWED_USERS do
			if player.UserId == userId then
				print("Allowing user", player.Name)
				return true
			end
		end

		return false
	end

	local function PlayerAdded(player)
		if ShouldAddFreeCam(player) then
			require(freecamScript)()
		end
	end

	Players.PlayerAdded:Connect(PlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(PlayerAdded, player)
	end
end

return Freecam
