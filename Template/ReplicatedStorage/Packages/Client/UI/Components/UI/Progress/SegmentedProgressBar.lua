--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local math = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.math)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {
	Bar: GuiObject;
	Segment: GuiObject;
	SegmentsCount: number;
	Value: Fusion.Value<number>;
	MaxValue: Fusion.Value<number>;
	InvertOrder: boolean?; --> Optional<false>
	DisableSpring: boolean?; --> Optional<false>
	SpringSpeed: number?; --> Optional<35>
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
	local Bar, Segment, SegmentsCount, Value, MaxValue, InvertOrder, DisableSpring, SpringSpeed, SpringDamper, ColorStops = table.destruct(Props, {
		'Bar', 'Segment', 'SegmentsCount', 'Value', 'MaxValue', 'InvertOrder', 'DisableSpring', 'SpringSpeed', 'SpringDamper', 'ColorStops'
	})

	assert(Bar, 'Missing prop "Bar"')
	assert(MaxValue, 'Missing prop "MaxValue"')
	assert(Value, 'Missing prop "Value"')
	assert(Segment, 'Missing prop "Segment"')
	assert(SegmentsCount, 'Missing prop "SegmentsCount"')


	local SegmentTemplate = Segment:Clone()
	local DefaultColor = SegmentTemplate.ImageColor3 or SegmentTemplate.BackgroundColor3
	
	SpringSpeed = SpringSpeed or 35
	Segment:Destroy()
		
	local ColorProperty = SegmentTemplate.ImageColor3 and 'ImageColor3' or 'BackgroundColor3'
	local TransparencyProperty = SegmentTemplate.ImageTransparency and 'ImageTransparency' or 'BackgroundTransparency'
		
	-- out prop requires same scope
	local Progress = Scope:Computed(function(use)
		return math.clamp01(use(Value) / use(MaxValue))
	end)
	
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
	
	local FinalColor = DisableSpring and InnerScope:Spring(Color, SpringSpeed, SpringDamper) or Color
	
	for i=1, SegmentsCount do
		local Segment = SegmentTemplate:Clone()
		Segment[ColorProperty] = DefaultColor
		
		Segment.Name = `Segment {i}`
		Segment.Parent = Bar

		local Transparency = Scope:Computed(function(use)
			local Count = math.ceil(SegmentsCount * use(Progress))
			local i = InvertOrder and i or SegmentsCount - i + 1

			return i <= Count and 0 or 1
		end)
		local FinalTransparency = DisableSpring and InnerScope:Spring(Transparency, SpringSpeed, SpringDamper) or Transparency
		
		InnerScope:Hydrate(Segment) {
			[TransparencyProperty] = FinalTransparency;
			[ColorProperty] = FinalColor;
		}
	end
	
	InnerScope:Hydrate(Bar)(Props)
	
	return Bar, {
		Scope = InnerScope;
		Progress = Progress;
	}
end