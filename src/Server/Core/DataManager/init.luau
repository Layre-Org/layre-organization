--</Services
local Players = game:GetService('Players')

--</Packages
local ProfileStore = require(script.ProfileStore)
local Template = require(script.Template)

--</Misc
type IProfile = ProfileStore.Profile<typeof(Template.Content)>

--</Store
local _PlayerStore = ProfileStore.New(Template.Settings.STORE_NAME, Template.Content)

if Template.Settings.USE_MOCK then
	_PlayerStore = _PlayerStore.Mock
end

--</Manager
local DataManager = {}
DataManager.Profiles = {} :: {[Player]: IProfile}

function DataManager:GetProfile(Client: Player): IProfile?
	local Profile = DataManager.Profiles[Client]
	local t = tick()

	while not Profile and Client.Parent == Players do
		if tick() - t >= Template.Settings.PROFILE_TIMEOUT then break end

		Profile = DataManager.Profiles[Client]
		task.wait()
	end

	return Profile
end

function DataManager:Get(Client: Player, Key: string)
	local Profile = DataManager:GetProfile(Client)
	if not Profile then return end

	return Profile.Data[Key]
end

function DataManager:Set(Client: Player, Key: string, Value: any)
	local Profile = DataManager:GetProfile(Client)
	if Profile then
		Profile.Data[Key] = Value
		return Profile.Data[Key]
	end
end

function DataManager:Update(Client: Player, Key: string, Callback: (any) -> any)
	local Profile = DataManager:GetProfile(Client)
	if Profile then
		Profile.Data[Key] = Callback(Profile.Data[Key])
		return Profile.Data[Key]
	end
end

function DataManager:OnPlayerAdded(Client: Player)
	if DataManager.Profiles[Client] then return end

	local Profile = _PlayerStore:StartSessionAsync(`{Client.UserId}`, {
		Cancel = function()
			return Client.Parent ~= Players
		end,
	}) 

	if not Profile then
		Client:Kick('Profile load fail - Please rejoin!') 
	end

	Profile:AddUserId(Client.UserId)
	Profile:Reconcile()

	Profile.OnSessionEnd:Connect(function()
		DataManager.Profiles[Client] = nil
		Client:Kick(`Profile session end - Please rejoin!`)
	end)

	if Client:IsDescendantOf(Players) then
		DataManager.Profiles[Client] = Profile

		if Template.Settings.LOG_ON_DATA_LOAD then
			print(`Loaded data for {Client.DisplayName}:`, Profile.Data)
		end
	else
		Profile:EndSession()
	end
end

function DataManager:OnPlayerRemoving(Client: Player)		
	local Profile = DataManager.Profiles[Client]
	if Profile then
		Profile:EndSession()
	end
end

return DataManager
