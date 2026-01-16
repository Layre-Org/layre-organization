--</Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--</Packages
local Component = require(ReplicatedStorage.Packages.Shared.Utility.Component)

local __name__ = Component.new({
	Tag = '__name__'
})

function __name__:Construct()
	__cursor__
end

return __name__