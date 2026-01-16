local Debounce = {}
Debounce.__index = Debounce

function Debounce.new()
	local self = setmetatable({}, Debounce)
	self._debounces = {}
	self._listeners = {}
	return self
end

function Debounce:register(key, time)
	if not self._debounces then self = _G.Debounce end
	if self._debounces[key] then
		return false
	end
	self._debounces[key] = true
	if time then
		task.delay(time, function()
			self:release(key)
		end)
	end
	return true
end

function Debounce:check(key)
	if not self._debounces then self = _G.Debounce end
	return not self._debounces[key]
end

function Debounce:listen(key, callback, id)
	if not self._debounces then self = _G.Debounce end
	if not self._listeners[key] then
		self._listeners[key] = {}
	end
	if id then
		self._listeners[key][id] = callback
	else
		table.insert(self._listeners[key], callback)
	end
end

function Debounce:release(key)
	if not self._debounces then self = _G.Debounce end
	self._debounces[key] = nil
	for _, listener in self._listeners[key] do
		listener()
	end
end

if not _G.Debounce then
	_G.Debounce = Debounce.new()
end
return Debounce
