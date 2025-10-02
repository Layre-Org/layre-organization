--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {
	Label: TextLabel;
	Value: Fusion.Value<number>;
	MaxValue: Fusion.Value<number>?; --> Optional<nil>
	Prefix: string?; --> Optional<nil>
	Suffix: string?; --> Optional<nil>
	Format: ((Current: number, Max: number) -> string)?; --> Optional<nil>
}

export type IReturn = {
	Scope: UIScope.Scope;
}

return function(Scope: UIScope.Scope, Props: IProps): IReturn
	local InnerScope = Scope:innerScope() :: UIScope.Scope
	local Label, Value, MaxValue, Prefix, Suffix, Format = table.destruct(Props, {
		'Label', 'Value', 'MaxValue', 'Prefix', 'Suffix', 'Format'
	})
	
	assert(Label, 'Missing prop "Label"')
	assert(Value, 'Missing prop "Value"')

	local FinalText = Scope:Computed(function(use)
		local Current = use(Value)
		local Max = MaxValue and use(MaxValue) or nil

		if Format then
			return Format(Current, Max)
		end

		local Clamped = Max and math.clamp(math.round(Current), 0, Max) or math.round(Current)
		local Text = tostring(Clamped)

		if Prefix then
			Text = `{Prefix} {Text}`
		end
		if Suffix then
			Text = `{Text} {Suffix}`
		end

		return Text
	end)
	
	Props.Text = Props.Text or FinalText

	Scope:Hydrate(Label)(Props)
	
	return Label, {
		Scope = InnerScope;
	}
end