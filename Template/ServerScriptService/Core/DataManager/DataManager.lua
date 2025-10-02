--</Services
local RS = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

--</Packages
local ProfileStore = require(script.ProfileStore)
local Template = require(script.Template)
	
local PlayerDataManager = {}
PlayerDataManager.PlayerStore = ProfileStore.New('_PlayerStore000', Template)
PlayerDataManager.Profiles = {} :: {[Player]: typeof(PlayerDataManager.PlayerStore:StartSessionAsync())}

function PlayerDataManager:GetProfile(Client: Player): typeof(PlayerDataManager.PlayerStore:StartSessionAsync())
	local Profile = PlayerDataManager.Profiles[Client]
	
	while not Profile and Client.Parent == Players do
		Profile = PlayerDataManager.Profiles[Client]
		if not Profile then
			break
		end
		task.wait()
	end
	
	return Profile
end

function PlayerDataManager:Get(Client: Player, Key: string)
	local Profile = PlayerDataManager.Profiles[Client]
	return Profile.Data[Key]
end

function PlayerDataManager:Set(Client: Player, Key: string, Value: any)
	local Profile = PlayerDataManager.Profiles[Client]
	if Profile then
		Profile.Data[Key] = Value
		return Profile.Data[Key]
	end
end

function PlayerDataManager:Update(Client: Player, Key: string, Callback: (any) -> any)
	local Profile = PlayerDataManager.Profiles[Client]
	if Profile then
		Profile.Data[Key] = Callback(Profile.Data[Key])
		return Profile.Data[Key]
	end
end

function PlayerDataManager:OnPlayerAdded(Client: Player)
	local Profile = PlayerDataManager.PlayerStore:StartSessionAsync(`{Client.UserId}`, {
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
		PlayerDataManager.Profiles[Client] = nil
		Client:Kick(`Profile session end - Please rejoin!`)
	end)
	
	if Client:IsDescendantOf(Players) then
		PlayerDataManager.Profiles[Client] = Profile
	else
		Profile:EndSession()
	end
end

function PlayerDataManager:OnPlayerRemoving(Client: Player)		
	local Profile = PlayerDataManager.Profiles[Client]
	if Profile then
		Profile:EndSession()
	end
end

return PlayerDataManager
