--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local table = require(ReplicatedStorage.Packages.Shared.Utility.LuaO.table)
local Module3D = require(ReplicatedStorage.Packages.Shared.Utility.Module3D)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)
local UIScope = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIScope)

export type IProps = {
	Parent: GuiObject;
	Model: Fusion.Value<Model>;
	Offset: CFrame?; --> Optional<nil>
}

export type IReturn = {
	Scope: UIScope.Scope;
	Model3D: 'Model3D';
}

return function(Scope: UIScope.Scope, Props: IProps): IReturn
	local InnerScope = Scope:innerScope() :: UIScope.Scope
	local Parent, Model, Offset = table.destruct(Props, { 'Parent', 'Model', 'Offset' })

	assert(Parent, 'Missing prop "Parent"')
	assert(Model, 'Missing prop "Model"')
	
	local Model3D = Module3D.new(Parent)
	Model3D.Camera.FieldOfView = 5
	Model3D:SetDepthMultiplier(1.2)
	
	if Props.Offset then
		Model3D:SetCFrame(Props.Offset)
	end
	
	InnerScope:Observer(Model):onBind(function()
		local Model = InnerScope.peek(Model)
		
		Model3D.AdornFrame.Visible = Model ~= nil
		Model3D:SetModel(Model)
	end)
	
	table.insert(InnerScope, Model3D)

	return {
		Scope = InnerScope;
		Model3D = Model3D;
	}
end