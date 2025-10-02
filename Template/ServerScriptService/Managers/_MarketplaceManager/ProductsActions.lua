--</Service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')

--</Packages
local ProductsSettings = require(ReplicatedStorage.Packages.Shared.Settings.Products)

local ProductsActions = {}

ProductsActions[ProductsSettings.Example.ProductId] = function(Client: Player)
	-- do some stuff
end


return ProductsActions
