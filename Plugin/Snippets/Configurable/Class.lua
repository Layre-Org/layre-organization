local __name__ = {}
__name__.__index = __name__

function __name__.new(): I__name__
	local self = setmetatable({}, __name__)
	__cursor__
	return self
end

export type I__name__ = typeof(setmetatable({} :: {}, __name__))

return __name__
