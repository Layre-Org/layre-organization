--</Service
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--</Service
local Gamepasses = require(ReplicatedStorage.Packages.Shared.Settings.Gamepass)

local PassActions = {}

--PassActions[Gamepasses.Example.PassId] = function(Client: Player)
--	Client.Gamepass:SetAttribute('Example', true)
--end

return PassActions
