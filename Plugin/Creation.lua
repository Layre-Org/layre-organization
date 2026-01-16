local Creation = {}

Creation.Paths = {
	['Managers'] = 'ServerScriptService.Managers',
	['EventsServer'] = 'ServerScriptService.Events',
	['ClassesServer'] = 'ServerScriptService.Classes',
	['HandlersServer'] = 'ServerScriptService.Handlers',
	['ComponentsServer'] = 'ServerScriptService.Components',

	['Controllers'] = 'ReplicatedStorage.Packages.Client.Controllers',
	['UIControllers'] = 'ReplicatedStorage.Packages.Client.UI.Controllers',
	['UIComponent'] = 'ReplicatedStorage.Packages.Client.UI.Components.UI',
	['UIStore'] = 'ReplicatedStorage.Packages.Client.UI.Stores',
	['ClassesClient'] = 'ReplicatedStorage.Packages.Client.Classes',
	['ComponentsClient'] = 'ReplicatedStorage.Packages.Client.Components',

	['Utility'] = 'ReplicatedStorage.Packages.Shared.Utility',
	['Packets'] = 'ReplicatedStorage.Packages.Shared.Packets',
	['Settings'] = 'ReplicatedStorage.Packages.Shared.Settings',
}

return Creation
