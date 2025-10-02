--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local math = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.math)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)
local IconComponent = require(script.Parent.Icon)

export type IProps = {
	Icon: GuiObject;
	Enabled: Fusion.Value<boolean>;
	
	DisableAnimation: boolean?; --> Optional<false>
	AnimationTime: number?; --> Optional<0.5>
	AnimationProperty: string?; --> Optional<'Transparency'>
	AnimationStyle: Enum.EasingStyle?; --> Optional<Enum.EasingStyle.Quart>
	AnimationDirection: Enum.EasingDirection; --> Optional<Enum.EasingDirection.InOu>
}

export type IReturn = {
	Scope: UIScope.Scope;
	Transparency: Fusion.Value<number>;
}

return function(Scope: UIScope.Scope, Props: IProps): IReturn
	local InnerScope = Scope:innerScope() :: UIScope.Scope
	local Icon, Enabled, DisableAnimation, AnimationTime, AnimationProperty, AnimationStyle, AnimationDirection = table.destruct(Props, {
		'Icon', 'Enabled', 'DisableAnimation', 'AnimationTime', 'AnimationProperty', 'AnimationStyle', 'AnimationDirection'
	})
	
	assert(Icon, 'Missing argument "Icon"')
	assert(Enabled, 'Missing argument "Enabled"')
	
	AnimationTime = AnimationTime or .5
	AnimationProperty = AnimationProperty or 'Transparency'
	AnimationStyle = AnimationStyle or Enum.EasingStyle.Quart
	AnimationDirection = AnimationDirection or Enum.EasingDirection.InOut
		
	-- out props requires same scope
	local IconTransparency = Scope:Computed(function(use) return use(Enabled) and 0 or 1 end)
	local FinalIconTransparency = Scope:Tween(IconTransparency, TweenInfo.new(AnimationTime, AnimationStyle, AnimationDirection, -1, true))
		
	Props[AnimationProperty] = FinalIconTransparency;
		
	IconComponent(InnerScope, { Icon = Icon, Enabled = Enabled })
	InnerScope:Hydrate(Icon)(Props)
	
	return Icon, { 
		Scope = InnerScope;
		Transparency = FinalIconTransparency;
	}
end