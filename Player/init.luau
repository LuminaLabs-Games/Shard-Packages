local Players = game:GetService("Players")

local Trove = require(script.Parent.Trove)

export type PlayerImpl = {
	_player: Player,
	_character: Model?,
	_subscriptions: { [string]: RBXScriptConnection },
	_properties: { [string]: any },

	subscribe: (event: string, callback: (any) -> ()) -> PlayerImpl,
	unsubscribe: (event: string) -> PlayerImpl,
	SetProperty: (property: string, value: any) -> PlayerImpl,
	GetProperty: (property: string) -> any,
	ObserveProperty: (property: string, callback: (any) -> ()) -> PlayerImpl,
	SetSpawn: (spawn: Instance) -> PlayerImpl,
	Destroy: () -> (),
}

local Player = {}
Player.__index = Player

local PlayerSingleton = setmetatable({}, Player)

function Player.new(player: Player)
	local self = setmetatable({}, Player)

	self._player = player
	self._character = nil
	self._subscriptions = {}
	self._properties = {
		Health = 100,
		MaxHealth = 100,
		WalkSpeed = 16,
		JumpPower = 50,
	}
	self._trove = Trove.new()

	player.CharacterAdded:Connect(function(character)
		self._character = character
	end)

	Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			self:Destroy()
		end
	end)

	return self
end

function Player:subscribe(event: string, callback: (any) -> ())
	local function handle(...)
		callback(...)
	end

	self._subscriptions[event] = handle

	return self
end

function Player:unsubscribe(event: string)
	self._subscriptions[event] = nil

	return self
end

function Player:SetProperty(property: string, value: any)
	if self._properties[property] then
		self._properties[property] = value
	end

	return self
end

function Player:GetProperty(property: string)
	return self._properties[property]
end

function Player:ObserveProperty(property: string, callback: (any) -> ())
	self._trove:Add(self._properties[property]:GetPropertyChangedSignal(property):Connect(callback))

	return self
end

function Player:SetSpawn(spawn: Instance)
	self._player.RespawnLocation = spawn

	return self
end

function Player:Destroy()
	for event, callback in self._subscriptions do
		self._subscriptions[event] = nil
	end

	self._subscriptions = {}

	self._player = nil
	self._character = nil
	self._properties = {}
	self._trove:Clean()

	setmetatable(self, nil)
end

return setmetatable(Player, {
	__index = PlayerSingleton,
	__call = function(_, player: Player)
		return Player.new(player) :: PlayerImpl
	end,
})
