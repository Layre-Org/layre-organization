--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {
	Icon: GuiObject;
	Enabled: Fusion.Value<boolean>;
}

export type IReturn = {
	Scope: UIScope.Scope
}

return function(Scope: UIScope.Scope, Props: IProps): IReturn
	local InnerScope = Scope:innerScope() :: UIScope.Scope
	local Icon, Enabled = table.destruct(Props, { 'Icon', 'Enabled' })

	assert(Icon, 'Missing argument "Icon"')
	assert(Enabled, 'Missing argument "Enabled"')
	
	Props.Visible = Props.Visible or Enabled

	InnerScope:Hydrate(Icon)(Props)

	return Icon, {
		Scope = InnerScope;
	}
end