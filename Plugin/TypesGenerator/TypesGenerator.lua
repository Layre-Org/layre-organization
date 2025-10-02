local Janitor = require(script.Parent.Utility.Janitor)
local _janitor = Janitor.new()

local TypesGenerator = {}

function TypesGenerator.Load()
	local UIPaths = require(script.UIPaths)
	local UIScope = require(script.UIScope)

	UIPaths.Load(_janitor)
	UIScope.Load(_janitor)
end

function TypesGenerator.Unload()
	_janitor:Destroy()
end

return TypesGenerator
