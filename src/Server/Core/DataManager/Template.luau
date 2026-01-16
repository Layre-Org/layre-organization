local Template = {}

Template.Content = {
	['Stats'] = {
		Cash = 0
	},
	
	['Inventory'] = {
		Infos = {
			TotalItems = 0,
			MaxItems = 25,
			MaxEquippedItems = 1,
			CurrentlyEquippedAmount = 0,
			CurrentlyEquippedIDs = {}
		},
		
		Items = {}
	},
}

Template.Settings = {
	STORE_NAME 			= '_GameStore000',
	PROFILE_TIMEOUT 	= 10,		-- Player data load timeout (in seconds)
	LOG_ON_DATA_LOAD 	= true,		-- Log to console when player data is loaded
	USE_MOCK 			= true,		-- Use mock data store for testing (data will not be saved)
}

return Template
