--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {
	Label: TextLabel;
	Text: Fusion.Value<string>;
	Format: ((Current: string) -> string)?; --> Optional<nil>
}

export type IReturn = {
	Scope: UIScope.Scope;
}

return function(Scope: UIScope.Scope, Props: IProps): IReturn
	local InnerScope = Scope:innerScope() :: UIScope.Scope
	local Label, Text, Format = table.destruct(Props, { 'Label', 'Text', 'Format' })
	
	assert(Label, 'Missing prop "Label"')
	assert(Text, 'Missing prop "Text"')
	
	local FinalText = Scope:Computed(function(use)
		local Current = use(Text)

		if Format then
			return Format(Current)
		end

		return tostring(Current)
	end)
	
	Props.Text = Props.Text or FinalText
	
	Scope:Hydrate(Label)(Props)

	return Label, {
		Scope = InnerScope;
	}
end