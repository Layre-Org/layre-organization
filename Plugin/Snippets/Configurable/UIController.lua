--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

--</Controller
local __name__ = {}

function __name__:Start(Scope: UIScope.Scope)
	print('__name__ Started!')__cursor__
end

return __name__
