--</Services
local ScriptEditorService = game:GetService("ScriptEditorService")

local Snippets = {}
Snippets.AutoComplete = {}
Snippets.Configurable = {}

local function Configure(Folder: Folder)
	for _, Module: ModuleScript in Folder:GetDescendants() do
		if not Module:IsA('ModuleScript') then continue end
		Snippets[Folder.Name][Module.Name] = Module.Source
	end
end

Configure(script.AutoComplete)
Configure(script.Configurable)

return Snippets

