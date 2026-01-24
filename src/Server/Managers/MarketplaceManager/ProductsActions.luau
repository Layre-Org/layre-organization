--</Service
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--</Packages
local PurchasesPackets = require(ReplicatedStorage.Packages.Shared.Packets.Purchases)
local ProductsSettings = require(ReplicatedStorage.Packages.Shared.Settings.Products)

local ProductsActions = {}

-- ProductsActions[ProductsSettings.Buy1xExtraPicking.ProductId] = function(Client: Player)
-- 	PurchasesPackets.OnProductPurchased.sendTo(true, Client)
-- end


return ProductsActions
