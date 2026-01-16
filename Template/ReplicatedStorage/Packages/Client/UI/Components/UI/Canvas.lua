--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {
	Canvas: CanvasGroup;
	Enabled: Fusion.Value<boolean>;
	DisableSpring: boolean?; --> Optional<false>
	SpringSpeed: number?; --> Optional<10>
	SpringDamper: number?; --> Optional<1>
}

export type IReturn = {
	Scope: UIScope.Scope;
	Transparency: Fusion.Value<number>;
	Visible: Fusion.Value<boolean>;
}

return function(Scope: UIScope.Scope, Props: IProps): IReturn
	local InnerScope = Scope:innerScope() :: UIScope.Scope

	assert(Props.Canvas, 'Missing prop "Canvas"')
	assert(Props.Enabled, 'Missing prop "Enabled"')

	local Canvas, Enabled, DisableSpring, SpringSpeed, SpringDamper = table.destruct(Props, {
		'Canvas', 'Enabled', 'DisableSpring', 'SpringSpeed', 'SpringDamper'
	})

	-- out props requires same scope
	local Transparency = Scope:Computed(function(use) return use(Enabled) and 0 or 1 end)
	local FinalTransparency = not DisableSpring and Scope:Spring(Transparency, SpringSpeed, SpringDamper) or Transparency
	local Visible = Scope:Computed(function(use) return use(FinalTransparency) < .99 end)

	local PropertyTable = Props
	PropertyTable.Visible = PropertyTable.Visible or Visible;
	PropertyTable.GroupTransparency = PropertyTable.GroupTransparency or FinalTransparency

	InnerScope:Hydrate(Canvas)(PropertyTable)

	return Canvas, { 
		Scope = InnerScope; 
		Transparency = FinalTransparency; 
		Visible = Visible;
	}
end
