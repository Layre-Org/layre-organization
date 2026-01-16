--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local math = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.math)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {
	Bar: GuiObject;
	Value: Fusion.Value<number>;
	MaxValue: Fusion.Value<number>;
	Axis: ('X' | 'Y')?; --> Optional<'X'>
	DisableSpring: boolean?; --> Optional<false>
	SpringSpeed: number?; --> Optional<10>
	SpringDamper: number?; --> Optional<5>
}

export type IReturn = {
	Scope: UIScope.Scope
}

return function(Scope: UIScope.Scope, Props: IProps): IReturn
	local InnerScope = Scope:innerScope() :: UIScope.Scope
	local Bar, Value, MaxValue, Axis, DisableSpring, SpringSpeed, SpringDamper = table.destruct(Props, {
		'Bar', 'Value', 'MaxValue', 'Axis', 'DisableSpring', 'SpringSpeed', 'SpringDamper'
	})
	
	assert(Bar, 'Missing prop "Bar"')
	assert(Value, 'Missing prop "Value"')
	assert(MaxValue, 'Missing prop "MaxValue"')

	Axis = Axis or 'X'

	local Size = InnerScope:Computed(function(use)
		local CurrentSize = Bar.Size
		local Ratio = math.clamp01(math.safeDivide(use(Value), use(MaxValue)))
		if Axis == 'X' then
			return UDim2.new(UDim.new(Ratio, CurrentSize.X.Offset), CurrentSize.Y)
		elseif Axis == 'Y' then
			return UDim2.new(CurrentSize.X, UDim.new(Ratio, CurrentSize.Y.Offset))
		end
	end)
	
	local FinalSize = DisableSpring and InnerScope:Spring(Size, SpringSpeed, SpringDamper) or Size
	
	Props.Size = Props.Size or FinalSize
	
	InnerScope:Hydrate(Bar)(Props)
	
	return Bar, {
		Scope = InnerScope
	}
end