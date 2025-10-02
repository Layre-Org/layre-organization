--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local math = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.math)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {
	Gradient: UIGradient;
	Value: Fusion.Value<number>;
	MaxValue: Fusion.Value<number>;
	Axis: Vector2;
	DisableSpring: boolean?; --> Optional<false>
	SpringSpeed: number?; --> Optional<10>
	SpringDamper: number?; --> Optional<5>
	ColorStops: { {
		Ratio: number;
		Color: Color3;
	} }?; --> Optional<nil>
}

export type IReturn = {
	Scope: UIScope.Scope;
	Progress: Fusion.Value<number>;
}

return function(Scope: UIScope.Scope, Props: IProps): IReturn
	local InnerScope = Scope:innerScope() :: UIScope.Scope
	local Gradient, Value, MaxValue, Axis, DisableSpring, SpringSpeed, SpringDamper, ColorStops = table.destruct(Props, {
		'Gradient', 'Value', 'MaxValue', 'Axis', 'DisableSpring', 'SpringSpeed', 'SpringDamper', 'ColorStops'
	})

	assert(Gradient, 'Missing prop "Gradient"')
	assert(MaxValue, 'Missing prop "MaxValue"')
	assert(Value, 'Missing prop "Value"')
	assert(Axis, 'Missing prop "Axis"')
	
	Axis = Axis.Unit
	local Angle = -math.deg(math.atan2(Axis.Y, Axis.X))
	local DefaultColor = Gradient.Color
	
	-- out prop requires same scope
	local Progress = Scope:Computed(function(use)
		return math.clamp01(use(Value) / use(MaxValue))
	end)
	local Offset = InnerScope:Computed(function(use)
		local Ratio = use(Progress)
		
		if math.abs(Axis.Y) > math.abs(Axis.X) then
			Ratio = 1 - Ratio
		end
		
		Ratio = math.mapClamped(Ratio, 0, 1, -.5, .5)
		return Axis * Ratio
	end);
	local Color = InnerScope:Computed(function(use)
		if not ColorStops or #ColorStops == 0 then
			return DefaultColor
		end
		
		local Ratio = use(Progress)
		local ColorStop = ColorStops[1]
		
		for _, Stop in ColorStops do
			if Ratio >= Stop.Ratio then
				ColorStop = Stop
			else
				break
			end
		end
		
		return ColorStop.Color
	end)
	
	local FinalColor = not DisableSpring and InnerScope:Spring(Color) or Color
	local FinalOffset = not DisableSpring and InnerScope:Spring(Offset) or Offset
	
	Props.Rotation = Props.Rotation or Angle
	Props.Offset = Props.Offset or FinalOffset
	Props.Color = Props.Color or InnerScope:Computed(function(use)
		return ColorSequence.new(use(FinalColor))
	end)
	Props.Transparency = Props.Transparency or NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0);
		NumberSequenceKeypoint.new(.499, 0);
		NumberSequenceKeypoint.new(.5, 1);
		NumberSequenceKeypoint.new(1, 1);
	})
	
	InnerScope:Hydrate(Gradient)(Props)
	
	return Gradient, {
		Scope = InnerScope;
		Progress = Progress;
	}
end