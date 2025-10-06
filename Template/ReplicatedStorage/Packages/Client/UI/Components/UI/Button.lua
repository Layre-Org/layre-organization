--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {
	Button: ImageButton | TextButton;
	ActivatedAction: (() -> ())?;
}

export type IReturn = {
	Scope: UIScope.Scope;
	IsHovering: Fusion.Value<boolean>;
}

return function(Scope: UIScope.Scope, Props: IProps): IReturn
	local InnerScope = Scope:innerScope() :: UIScope.Scope
	
	local Button, ActivatedAction = table.destruct(Props, { 'Button', 'ActivatedAction' })
	
	assert(Button, 'Missing prop "Button"')
	
	-- out props requires same scope
	local IsHovering = Scope:Value(false)
	
	if ActivatedAction then
		Props[Scope.OnEvent 'Activated'] = ActivatedAction
	end
	Props[Scope.OnEvent 'MouseEnter'] = function()
		IsHovering:set(true)
	end
	Props[Scope.OnEvent 'MouseLeave'] = function()
		IsHovering:set(false)
	end

	InnerScope:Hydrate(Button)(Props)
	
	return Button, {
		Scope = InnerScope;
		IsHovering = IsHovering
	}
end
