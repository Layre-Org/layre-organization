--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local math = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.math)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {
	Indicator: GuiObject;
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
	local Indicator, Value, MaxValue, Axis, DisableSpring, SpringSpeed, SpringDamper = table.destruct(Props, {
		'Indicator', 'Value', 'MaxValue', 'Axis', 'DisableSpring', 'SpringSpeed', 'SpringDamper'
	})
	
	assert(Indicator, 'Missing prop "Indicator"')
	assert(Value, 'Missing prop "Value"')
	assert(MaxValue, 'Missing prop "MaxValue"')

	Axis = Axis or 'X'

	local Position = InnerScope:Computed(function(use)
		local CurrentPosition = Indicator.Position
		local Ratio = math.clamp01(math.safeDivide(use(Value), use(MaxValue)))
		
		if Axis == 'X' then
			return UDim2.new(UDim.new(Ratio, CurrentPosition.X.Offset), CurrentPosition.Y)
		elseif Axis == 'Y' then
			return UDim2.new(CurrentPosition.X, UDim.new(Ratio, CurrentPosition.Y.Offset))
		end
	end)
	
	local FinalPosition = DisableSpring and InnerScope:Spring(Position, SpringSpeed, SpringDamper) or Position
	
	Props.Position = Props.Position or FinalPosition
	
	InnerScope:Hydrate(Indicator)(Props)
	
	return Indicator, {
		Scope = InnerScope
	}
end