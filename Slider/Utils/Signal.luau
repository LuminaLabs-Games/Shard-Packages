--!strict

local FastSpawnListener = Instance.new('BindableFunction')

FastSpawnListener.OnInvoke = function(cb: (...any) -> (), ...: any)
	cb(...)
end :: any

export type Connection = {
	Connected: boolean,
	Disconnect: () -> (),
	Destroy: () -> (),
}
export type FunctionArgs<T> = any --[[typeof((function(...)
	local x: T
	x(...)
	return ...
end)())]]
export type Signal<T> = {
	Connect: (Signal<T>, T) -> Connection,
	Wait: (Signal<T>) -> ...FunctionArgs<T>,
	Fire: (Signal<T>, ...FunctionArgs<T>) -> (),
	Destroy: () -> (),
}

local Connection = {}
Connection.__index = {}

function Connection.__index.Disconnect(self: any)
	if self.Connected then
		self.Connected = false
		self._signal._cbSet[self._cb] = nil
		self._signal = nil
		self._cb = nil
	end
end
Connection.__index.Destroy = Connection.__index.Disconnect

function Connection.new(_signal: any, _cb: any): Connection
	local self = {}
	setmetatable(self, Connection)
	self.Connected = true
	self._signal = _signal
	self._cb = _cb
	
	return self :: any
end

local Signal = {}
Signal.__index = {}

function Signal.__index.Connect(self: any, cb: any): Connection
	local conn = Connection.new(self, cb)
	self._cbSet[cb] = true
	return conn
end

function Signal.__index.Destroy(self: any)
	self._cbSet = {}
	self._threads = {}
end

function Signal.__index.Wait(self: any): ...any
	local thread = coroutine.running()
	table.insert(self._threads, thread)
	return coroutine.yield()
end

function Signal.__index.Fire(self: any, ...: any)
	local cbs = {}
	for cb in pairs(self._cbSet) do
		table.insert(cbs, cb)
	end
	for i = 1, #cbs do
		local cb = cbs[i]
		coroutine.resume(
			coroutine.create(
				function(...)
					FastSpawnListener:Invoke(cb, ...)
				end
			),
			...
		)
	end
	
	local threads = self._threads
	if #threads > 0 then
		self._threads = {}
		for i = 1, #threads do
			coroutine.resume(threads[i], ...)
		end
	end
end

function Signal.new(): Signal<any>
	local self = {}
	setmetatable(self, Signal)
	
	self._cbSet = {}
	self._threads = {}
	
	return self :: any
end

return Signal