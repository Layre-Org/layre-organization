--</Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SSS = game:GetService('ServerScriptService')

--</Packages
local PlayerDataManager = require(SSS.Core.DataManager)
local ProductsActions = require(script.ProductsActions)
local PassActions = require(script.PassActions)

local PURCHASE_ID_CACHE_SIZE = 300

local function PurchaseIdCheckAsync(Profile, PurchaseId, Action): Enum.ProductPurchaseDecision
	if Profile:IsActive() then
		local PurchaceIdCache = Profile.Data.PurchaseIdCache

		if not PurchaceIdCache then
			PurchaceIdCache = {}
			Profile.Data.PurchaseIdCache = PurchaceIdCache
		end

		if not table.find(PurchaceIdCache, PurchaseId) then
			local Sucess, Result = pcall(Action)
			if not Sucess then
				warn(`Failed to process receipt:`, Profile.Key, PurchaseId, Result)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			while #PurchaceIdCache >= PURCHASE_ID_CACHE_SIZE do
				table.remove(PurchaceIdCache, 1)
			end

			table.insert(PurchaceIdCache, PurchaseId)
		end

		local function IsPurchaseSaved()
			local SavedCache = Profile.LastSavedData.PurchaseIdCache
			return if SavedCache then table.find(SavedCache, PurchaseId) ~= nil else false
		end

		if IsPurchaseSaved() then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		while Profile:IsActive() do
			local LastSavedData = Profile.LastSavedData

			Profile:Save()

			if Profile.LastSavedData == LastSavedData then
				Profile.OnAfterSave:Wait()
			end

			if IsPurchaseSaved() then
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end

			if Profile:IsActive() then
				task.wait(10)
			end
		end
	end
end

local MarketplaceManager = {}

function MarketplaceManager:Start()
	MarketplaceService.ProcessReceipt = function(...) 
		return self:ProcessReceipt(...) 
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(...)
		return self:OnPromptPurchaseFinished(...)
	end)
end

function MarketplaceManager:OnPlayerAdded(Client: Player)
	local GamepassesFolder = Instance.new('Folder')
	GamepassesFolder.Name = 'Gamepass'
	GamepassesFolder.Parent = Client
	for PassId, Action in PassActions do
		local HasPass = false--MarketplaceService:UserOwnsGamePassAsync(Client.UserId, PassId)
		if HasPass then
			Action(Client)
		end
	end
end

function MarketplaceManager:ProcessReceipt(ReceiptInfo)
	local Client = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)

	if Client then
		local Profile = PlayerDataManager:GetProfile(Client)

		if Profile then
			if not ProductsActions[ReceiptInfo.ProductId] then
				warn(`No product function defined for ProductId {ReceiptInfo.ProductId}; Player: {Client.Name}`)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			return PurchaseIdCheckAsync(
				Profile,
				ReceiptInfo.PurchaseId,
				function()
					ProductsActions[ReceiptInfo.ProductId](Client)
				end
			)
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MarketplaceManager:OnPromptPurchaseFinished(Client: Player, PassId: number, IsPurchased: boolean)
	if not IsPurchased then return end

	local Action = PassActions[PassId]
	local Sucess, ErrorMessage = pcall(Action, Client)

	if not Sucess then
		warn('Failed to process pass: ', PassId, ErrorMessage)
	end
end

return MarketplaceManager
