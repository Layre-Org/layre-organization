--</Services
local ServerScriptService = game:GetService("ServerScriptService")

--</Packages
local DataManager = require(ServerScriptService.Core.DataManager)

--</Types
export type Currency = 'Coins'

local StatsManager = {}

function StatsManager:OnPlayerAdded(Client: Player)
	local StatsData = DataManager:Get(Client, 'Stats')
	
	Client:SetAttribute('Coins', StatsData.Coins or 0)
end

function StatsManager:AddCurrency(Client: Player, Currency: Currency, Amount: number)
	local CurrentAmount = StatsManager:GetCurrency(Client, Currency)
	local NewAmount = math.max(CurrentAmount + Amount, 0)

	DataManager:Update(Client, 'Stats', function(StatsData)
		StatsData[Currency] = NewAmount
		return StatsData
	end)

	Client:SetAttribute(Currency, NewAmount)
end

function StatsManager:GetCurrency(Client: Player, Currency: Currency)
	return Client:GetAttribute(Currency)
end

function StatsManager:HasEnoughCurrency(Client: Player, Currency: Currency, Value: number)
	return StatsManager:GetCurrency(Client, Currency) >= Value
end

return StatsManager