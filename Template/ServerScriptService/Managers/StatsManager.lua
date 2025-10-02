--</Services
local SSS = game:GetService('ServerScriptService')
local RS = game:GetService('ReplicatedStorage')

--</Packages
--local PlayerData = require(SSS.Core.DataManager)

--</Types
export type Currency = 'Coins'

local PlayerStatsManager = {}

function PlayerStatsManager:OnPlayerAdded(Client: Player)
	--</Currency
	--Client:SetAttribute('Coins',          PlayerData:Get(Client, 'Coins'))
	Client:SetAttribute('Coins', 0)
	
	--</Health
	--Client:SetAttribute('MaxHealth', )
	--Client:SetAttribute('Health', )
end

function PlayerStatsManager:AddCurrency(Client: Player, Currency: Currency, Amount: number)
	local NewAmount = Client:GetAttribute(Currency) + Amount --[[PlayerData:Update(Client, Currency, function(CurrentAmount: number)
		return math.max(CurrentAmount + Amount, 0)
	end)]]
	
	Client:SetAttribute(Currency, NewAmount)
end

function PlayerStatsManager:GetCurrency(Client: Player, Currency: Currency)
	return Client:GetAttribute(Currency)
end

function PlayerStatsManager:HasEnoughCurrency(Client: Player, Currency: Currency, Value: number)
	return PlayerStatsManager:GetCurrency(Client, Currency) >= Value
end

return PlayerStatsManager