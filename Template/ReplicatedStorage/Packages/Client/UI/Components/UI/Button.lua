--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {
	Button: ImageButton | TextButton;
	ActivatedAction: () -> ();
}

export type IReturn = {
	Scope: UIScope.Scope
}

return function(Scope: UIScope.Scope, Props: IProps): IReturn
	local InnerScope = Scope:innerScope() :: UIScope.Scope
	
	local Button, ActivatedAction = table.destruct(Props, { 'Button', 'ActivatedAction' })
	
	assert(Button, 'Missing prop "Button"')
	assert(ActivatedAction, 'Missing prop "ActivatedAction"')
	
	Props[Scope.OnEvent 'Activated'] = ActivatedAction

	InnerScope:Hydrate(Button)(Props)
	
	return Button, {
		Scope = InnerScope;
	}
end