--</Services
local ServerScriptService = game:GetService('ServerScriptService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

--</Packages
local Janitor = require(ReplicatedStorage.Packages.Shared.Utility.Janitor)
local ComponentsFolder = ServerScriptService.Components
local ManagersFolder = ServerScriptService.Managers
local PacketsFolder = ReplicatedStorage.Packages.Shared.Packets
local DataManager = require(script.Parent.DataManager)

local Managers = {}

local function LoadModules(Container: Folder)
	for _, Module: ModuleScript in Container:GetDescendants() do
		if not Module:IsA('ModuleScript') then continue end
		require(Module)
	end
end

local function CallStep(Managers: {}, Step: string, ...)
	local args = {...}
	for Name, Manager in Managers do
		if Manager[Step] then
			local response, message = xpcall(function()
				Manager[Step](Manager, table.unpack(args))
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
				errorMessage ..= '\n\n--<  Full Stackrace  >--'

				for _, part in parts do
					errorMessage ..= `\n\n{part}`
				end

				errorMessage ..= '\n\n--<  Original Error  >--\n\n' .. message

				warn(errorMessage)
			end
		end
	end
end


local function OnPlayerDied(Client: Player, Char: Model)
	CallStep(Managers, 'OnPlayerDied', Client, Char)
	if Client:GetAttribute('RespawnTime') then
		task.delay(Client:GetAttribute('RespawnTime'), function()
			Client:LoadCharacter()
		end)
	end
end

local function OnPlayerSpawn(Client: Player, Char: Model)
	local Human: Humanoid = Char:WaitForChild('Humanoid')
	Human.Died:Once(function()
		OnPlayerDied(Client, Char)
	end)
	Client:SetAttribute('Health', Client:GetAttribute('MaxHealth'))
	Human.MaxHealth = Client:GetAttribute('MaxHealth')
	Human.Health = Client:GetAttribute('MaxHealth')

	CallStep(Managers, 'OnPlayerSpawn', Client, Char)
end

local function OnPlayerAdded(Client: Player)
	if Client.Character then OnPlayerSpawn(Client, Client.Character) end
	Client.CharacterAppearanceLoaded:Connect(function(Char: Model)
		OnPlayerSpawn(Client, Char)
	end)

	Client:SetAttribute('Health', 100)
	Client:SetAttribute('MaxHealth', 100)
	Client:SetAttribute('RespawnTime', 2)

	Client:GetAttributeChangedSignal('Health'):Connect(function()
		local Char = Client.Character
		if not Char then return end

		local Human: Humanoid = Char:FindFirstChild('Humanoid')
		local Health = math.clamp(Client:GetAttribute('Health'), 0, Human.MaxHealth)

		if Health ~= Client:GetAttribute('Health') then
			Client:SetAttribute('Health', Health)
			return
		end

		Human.Health = Health
	end)
	Client:GetAttributeChangedSignal('MaxHealth'):Connect(function()
		local Char = Client.Character
		if not Char then return end

		local Human: Humanoid = Char:FindFirstChild('Humanoid')
		local MaxHealth = math.max(Client:GetAttribute('MaxHealth'), 1)

		if MaxHealth ~= Client:GetAttribute('MaxHealth') then
			Client:SetAttribute('MaxHealth', MaxHealth)
		end

		if MaxHealth < Client:GetAttribute('Health') then
			Client:SetAttribute('Health', MaxHealth)
		end

		Human.MaxHealth = MaxHealth
	end)

	DataManager:OnPlayerAdded(Client)

	CallStep(Managers, 'OnPlayerAdded', Client)
	Client:LoadCharacter()
	Client:SetAttribute('ServerInitialized', true)
end

local function OnPlayerRemoving(Client: Player)
	DataManager:OnPlayerRemoving(Client)
	CallStep(Managers, 'OnPlayerRemoving', Client)
end

local function BindEvents(Managers)
	for _, Client: Player in Players:GetPlayers() do task.spawn(OnPlayerAdded, Client) end
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	local Update = false
	local FixedUpdate = false

	for _, Manager in Managers do
		if Manager['Update'] then
			Update = true
		end
		if Manager['FixedUpdate'] then
			FixedUpdate = true
		end
	end

	if Update then
		RunService.Stepped:Connect(function(_, DeltaTime: number)
			CallStep(Managers, 'Update', DeltaTime)
		end)
	end

	if FixedUpdate then
		RunService.PostSimulation:Connect(function(DeltaTime: number)
			CallStep(Managers, 'FixedUpdate', DeltaTime)
		end)
	end
end

function Initialize()
	Players.CharacterAutoLoads = false

	for _, Module in ManagersFolder:GetDescendants() do
		if string.find(Module.Name, '_') or not string.find(Module.Name, 'Manager') or not Module:IsA('ModuleScript') then continue end
		local BaseModule = require(Module)
		if BaseModule.Janitor == true then
			BaseModule.__Janitor = Janitor.new()
			BaseModule.CleanUp = function(self) self.__Janitor:Cleanup() end
			BaseModule.Add = function(self, Process, DestroyCall) self.__Janitor:Add(Process, DestroyCall) end
			BaseModule.Janitor = nil
		end
		Managers[Module] = BaseModule
	end

	LoadModules(PacketsFolder)

	CallStep(Managers, 'Setup')
	CallStep(Managers, 'Start')
	CallStep(Managers, 'Awake')

	LoadModules(ComponentsFolder)

	BindEvents(Managers)
end

Initialize()
