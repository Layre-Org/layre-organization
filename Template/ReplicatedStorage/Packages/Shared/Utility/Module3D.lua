local FAR_POSITION = Vector3.new(0, 10000, 0)

local Module3D = {}
local Prototype = {}
Prototype.__index = Prototype

function Prototype:_computeCameraDistance(maxSize, fieldOfView, depthMultiplier)
	-- distância necessária para caber o bounding box no FOV vertical
	local halfFovRad = math.rad(fieldOfView * 0.5)
	if halfFovRad == 0 then return (maxSize * depthMultiplier) end
	return ((maxSize * 0.5) / math.tan(halfFovRad)) * (depthMultiplier or 1)
end

function Prototype:Update()
	if not (self.Object3D and self.Camera) then return end

	local boundingCFrame, boundingSize = self.Object3D:GetBoundingBox()
	local modelCenter = boundingCFrame.p

	local maxSize = math.max(boundingSize.X, boundingSize.Y, boundingSize.Z)
	local distanceBack = self:_computeCameraDistance(maxSize, self.Camera.FieldOfView, self.DepthMultiplier or 1)

	local center = CFrame.new(modelCenter)
	self.Camera.CFrame = center * (self.CFrameOffset or CFrame.identity) * CFrame.new(0, 0, distanceBack)
	self.Camera.Focus = center
end

function Prototype:SetCFrame(newCF)
	self.CFrameOffset = newCF or CFrame.identity
	self:Update()
end

function Prototype:GetCFrame()
	return self.CFrameOffset
end

function Prototype:SetDepthMultiplier(mult)
	self.DepthMultiplier = mult or 1
	self:Update()
end

function Prototype:GetDepthMultiplier()
	return self.DepthMultiplier
end

function Prototype:Destroy()
	if self.AdornFrame and self.AdornFrame.Parent then
		self.AdornFrame:Destroy()
	end

	if self.Object3D then
		-- reparenta o model original de volta (não destruir)
		self.Object3D.Parent = self._originalParent
	end

	if self._frameConnection then
		self._frameConnection:Disconnect()
		self._frameConnection = nil
	end

	setmetatable(self, nil)
	table.clear(self)
end

function Prototype:SetModel(Model)
	if self.Object3D then
		self.Object3D:Destroy()
	end

	if not Model then return end

	self._originalParent = Model.Parent
	self.Object3D = Model

	if Model:IsA("BasePart") then
		local NewModel = Instance.new("Model")
		NewModel.Name = "Model3D"
		Model.Parent = NewModel
		NewModel.PrimaryPart = Model

		Model = NewModel
		self.Object3D = Model
	end


	local basePrimary = Model.PrimaryPart
	if not basePrimary then
		Model.PrimaryPart = Model:FindFirstChildWhichIsA("BasePart", true)
	end

	if Model.PrimaryPart then
		Model:PivotTo(CFrame.new(FAR_POSITION - Model.PrimaryPart.Position) * Model.PrimaryPart.CFrame)
		Model.PrimaryPart = basePrimary
	end

	Model.Parent = self.AdornFrame
	self:Update()
end

function Module3D.new(Parent)
	local self = setmetatable({}, Prototype)

	self.CFrameOffset = CFrame.identity
	self.DepthMultiplier = 1

	local ViewportFrame = Instance.new("ViewportFrame")
	ViewportFrame.BackgroundTransparency = 1
	ViewportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	ViewportFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	ViewportFrame.Visible = false
	ViewportFrame.Parent = Parent
	self.AdornFrame = ViewportFrame

	local Camera = Instance.new("Camera")
	Camera.Parent = ViewportFrame
	ViewportFrame.CurrentCamera = Camera
	self.Camera = Camera

	local function UpdateFrameSize()
		local abs = Parent.AbsoluteSize
		local minSize = math.min(abs.X, abs.Y)
		ViewportFrame.Size = UDim2.new(0, minSize, 0, minSize)
	end

	local ok, conn = pcall(function()
		return Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateFrameSize)
	end)
	UpdateFrameSize()

	return self
end

return Module3D
