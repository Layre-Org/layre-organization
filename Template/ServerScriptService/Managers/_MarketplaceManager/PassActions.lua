--</Service
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--</Service
local Gamepasses = require(ReplicatedStorage.Packages.Shared.Settings.Gamepass)

local PassActions = {}

local function GetFolder(Client: Player): Folder
	return Client.Gamepass
end

PassActions[Gamepasses.Example.PassId] = function(Client: Player)
	GetFolder(Client):SetAttribute('Example', true)
end

return PassActions
