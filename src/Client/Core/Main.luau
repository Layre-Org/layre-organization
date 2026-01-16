--</Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

--</Player
local LocalClient = Players.LocalPlayer

--</Packages
local Janitor = require(ReplicatedStorage.Packages.Shared.Utility.Janitor)
local Fusion = require(ReplicatedStorage.Packages.Shared.Utility.Fusion)

--</Misc
local ComponentsFolder = ReplicatedStorage.Packages.Client.Components
local PacketsFolder = ReplicatedStorage.Packages.Shared.Packets
local ControllersFolder = ReplicatedStorage.Packages.Client.Controllers
local UIFolder = ReplicatedStorage.Packages.Client.UI

local Controllers = {}
local UIControllers = {}
local UIStores = {}

local function WaitForServer()
	if not LocalClient:GetAttribute('ServerInitialized') then
		LocalClient:GetAttributeChangedSignal('ServerInitialized'):Wait()
		WaitForServer()
	end
end

local function LoadModules(Container: Folder)
	for _, Module: ModuleScript in Container:GetDescendants() do
		if not Module:IsA('ModuleScript') then continue end
		require(Module)
	end
end

local function CallStep(Controllers: {}, Step: string, ...)
	local args = {...}
	for Name, Controller in Controllers do
		if Controller[Step] then			
			local response, message = xpcall(function()
				Controller[Step](Controller, table.unpack(args))
			end, function(Error)
				return debug.traceback(Error, 2)
			end)
			if not response then
				local parts = string.split(message, '\n')
				local errorParts = string.split(parts[1], ':')
				local path, line = errorParts[1], errorParts[2]
				table.remove(errorParts, 1)
				table.remove(errorParts, 1)
				table.remove(parts, 1)
				local fullMessage = table.concat(errorParts, ':')

				local pathParts = string.split(path, '.')
				local serviceName = pathParts[1]
				local parentFolder = pathParts[#pathParts-1]
				local errorOwner = pathParts[#pathParts]
				local errorMessage = `[{parentFolder} -> {errorOwner}] Error during execution of [{Step}] at line [{line}]:\n\n{fullMessage}`
				errorMessage ..= '\n\n--<  Full Stacktrace  >--'

				for _, part in parts do
					errorMessage ..= `\n\n{part}`
				end

				errorMessage ..= '\n\n--<  Original Error  >--\n\n' .. message

				warn(errorMessage)
			end
		end
	end
end

local function OnPlayerDied(Char: Model)
	CallStep(Controllers, 'OnPlayerDied', Char)
	CallStep(UIStores, 'OnPlayerDied', Char)
	CallStep(UIControllers, 'OnPlayerDied', Char)
end

local function OnPlayerSpawn(Char: Model)
	local Human: Humanoid = Char:WaitForChild('Humanoid')
	Human.Died:Once(function()
		OnPlayerDied(Char)
	end)

	CallStep(Controllers, 'OnPlayerSpawn', Char)
	CallStep(UIStores, 'OnPlayerSpawn', Char)
	CallStep(UIControllers, 'OnPlayerSpawn', Char)
end

local function OnPlayerAdded(Client: Player)
	CallStep(Controllers, 'OnPlayerAdded', Client)
	CallStep(UIStores, 'OnPlayerAdded', Client)
	CallStep(UIControllers, 'OnPlayerAdded', Client)

	if Client == LocalClient then
		if Client.Character then OnPlayerSpawn(Client.Character) end
		Client.CharacterAdded:Connect(function(Char: Model)
			OnPlayerSpawn(Char)
		end)
	end
end

local function OnPlayerRemoving(Client: Player)
	CallStep(Controllers, 'OnPlayerRemoving', Client)
	CallStep(UIStores, 'OnPlayerRemoving', Client)
	CallStep(UIControllers, 'OnPlayerRemoving', Client)
end

local function BindLoopEvents(Controllers)
	local Update = false
	local FixedUpdate = false

	for _, Controller in Controllers do
		if Controller['Update'] then
			Update = true
		end
		if Controller['FixedUpdate'] then
			FixedUpdate = true
		end
	end
	for _, Controller in UIControllers do
		if Controller['Update'] then
			Update = true
		end
		if Controller['FixedUpdate'] then
			FixedUpdate = true
		end
	end

	if Update then
		RunService.RenderStepped:Connect(function(DeltaTime: number)
			CallStep(Controllers, 'Update', DeltaTime)
		end)
	end

	if FixedUpdate then
		RunService.PostSimulation:Connect(function(DeltaTime: number)
			CallStep(Controllers, 'FixedUpdate', DeltaTime)
		end)
	end
end

function Initialize()
	LoadModules(PacketsFolder)

	for _, Module in ControllersFolder:GetDescendants() do
		if string.find(Module.Name, '_') or not string.find(Module.Name, 'Controller') or not Module:IsA('ModuleScript') then continue end
		local BaseModule = require(Module)
		if BaseModule.Janitor == true then
			BaseModule.Janitor = Janitor.new()
			BaseModule.Cleanup = function(self) self.Janitor:Cleanup() end
			BaseModule.Add = function(self, Process, DestroyCall, index) self.Janitor:Add(Process, DestroyCall, index) end
			BaseModule.Remove = function(self, index) self.Janitor:Remove(index) end
		end
		Controllers[Module] = BaseModule
	end


	CallStep(Controllers, 'Setup')

	WaitForServer()

	local Paths = UIFolder:FindFirstChild('Paths')
	local UIComponents = UIFolder:FindFirstChild('Components')
	local PathsMod = {}
	if Paths then
		PathsMod = require(Paths)
	end

	for _, Module in UIFolder:GetDescendants() do
		if Module == UIFolder.Paths then continue end
		if string.find(Module.Name, '_') or not Module:IsA('ModuleScript') then continue end

		local Req = require(Module)
		if typeof(Req) ~= 'table' then continue end

		if Req.Janitor == true then
			Req.Janitor = Janitor.new()
			Req.Cleanup = function(self) self.Janitor:Cleanup() end
			Req.Add = function(self, Process, DestroyCall, index) self.Janitor:Add(Process, DestroyCall, index) end
			Req.Remove = function(self, index) self.Janitor:Remove(index) end
		end

		if Module:IsDescendantOf(UIFolder.Controllers) then
			UIControllers[Module] = Req
		else
			UIStores[Module] = Req
		end
	end

	local Components = {}
	for _, Component in UIComponents:GetDescendants() do
		if not Component:IsA('ModuleScript') then continue end
		Components[Component.Name] = function(Scope)
			return function(...)
				return require(Component)(Scope, ...)
			end
		end
	end

	local Stores = {}
	for Mod, Store in UIStores do
		Stores[Mod.Name] = Store
	end

	local Scope; Scope = Fusion.scoped(Fusion, Components, {
		AttributeValue = function(self: Fusion.Scope, Attribute: string, DefaultValue: any)
			local Value = self:Value(LocalClient:GetAttribute(Attribute) or DefaultValue)
			local Connection = LocalClient:GetAttributeChangedSignal(Attribute):Connect(function() 
				Value:set(LocalClient:GetAttribute(Attribute) or DefaultValue) 
			end)
			table.insert(Scope, Connection)
			return Value
		end;
		Paths = PathsMod;
		Stores = Stores;
	})

	CallStep(Controllers, 'Start')
	CallStep(Controllers, 'Awake')

	LoadModules(ComponentsFolder)

	CallStep(UIStores, 'Start', Scope)
	CallStep(UIControllers, 'Start', Scope)

	for _, Client: Player in Players:GetPlayers() do task.spawn(OnPlayerAdded, Client) end
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	BindLoopEvents(Controllers)
	BindLoopEvents(UIStores)
	BindLoopEvents(UIControllers)
end

Initialize()
