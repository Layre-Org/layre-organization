--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {}

export type IReturn = {
	Scope: UIScope.Scope
}

return function(Scope: UIScope.Scope, Props: IProps): IReturn
	local InnerScope = Scope:innerScope() :: UIScope.Scope

	__cursor__
	
	return {
		Scope = InnerScope;
	}
end