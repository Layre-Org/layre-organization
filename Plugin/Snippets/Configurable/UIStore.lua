--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type I__name__Store = {
	
}

local __name__Store = {} :: I__name__Store

function __name__Store:Start(Scope: UIScope.Scope)
	self.Scope = Scope

	__cursor__
end

return __name__Store
