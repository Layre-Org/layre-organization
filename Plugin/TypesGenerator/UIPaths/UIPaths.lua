--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ScriptEditorService = game:GetService("ScriptEditorService")

--</Misc
local Template = script.Template
local TypesFolder = nil

local function trim(s)
	if not s then return "" end
	return s:match("^%s*(.-)%s*$")
end

function FindInstanceInArray(Array, Name)
	for _, Value in Array do
		if Value.Name == Name then
			return Value
		end
	end
end

function RemoveInstanceClones(Array)
	local NoClones = {}
	for _, Value in Array do
		if not FindInstanceInArray(NoClones, Value.Name) then
			table.insert(NoClones, Value)
		end
	end
	return NoClones
end

function GetTypesFolder()
	local Folder = ReplicatedStorage:FindFirstChild('Types', true)
	if Folder and Folder.Parent and Folder.Parent.Name == 'Shared' then
		return Folder
	end
end

function GetGensFolder()
	local Folder = TypesFolder:FindFirstChild('__generated')
	if not Folder then
		Folder = Instance.new('Folder')
		Folder.Name = '__generated'
		Folder.Parent = TypesFolder
	end
	return Folder
end

function GetGenModule()
	local Module = GetGensFolder():FindFirstChild('UIPaths')
	if not Module then
		Module = Instance.new('ModuleScript')
		Module.Name = 'UIPaths'
		Module.Parent = GetGensFolder()
	end
	return Module
end

-- sanitize identifier for Luau types (letters, numbers, underscore). prefix with '_' if starts with digit
local function sanitizeIdentifier(name)
	if not name or name == "" then return "_" end
	-- replace invalid chars with underscore
	local s = name:gsub("[^%w_]", "_")
	-- if starts with digit, prefix
	if s:match("^[0-9]") then
		s = "_" .. s
	end
	-- avoid empty
	if s == "" then s = "_" end
	return s
end

-- build type name from parts: {"Hud","Holder","Panels"} -> "Path_Hud_Holder_Panels"
local function typeNameFromParts(parts)
	local safe = {}
	for i, p in ipairs(parts) do
		table.insert(safe, sanitizeIdentifier(p))
	end
	return "Path_" .. table.concat(safe, "_")
end

-- collect node info by walking the StarterGui tree
local function collectNodeTypes(rootInstances)
	local types = {} -- map: typeName -> { className = "Frame", parts = {...}, children = { childName -> childTypeName } }

	local function walk(instance, parts)
		local tn = typeNameFromParts(parts)
		if not types[tn] then
			types[tn] = { className = instance.ClassName or "Instance", parts = { unpack(parts) }, children = {} }
		end

		-- iterate children (remove clones duplicates by name)
		local childs = RemoveInstanceClones(instance:GetChildren())
		for _, child in ipairs(childs) do
			local childParts = { unpack(parts) }
			table.insert(childParts, child.Name)
			local childTypeName = typeNameFromParts(childParts)
			types[tn].children[child.Name] = childTypeName
			walk(child, childParts)
		end
	end

	for _, top in ipairs(rootInstances) do
		-- ignore non-Instance just in case
		if typeof(top) == "Instance" then
			walk(top, { top.Name })
		end
	end

	return types
end

-- render Luau type lines for each collected node type
local function generateTypesLines(types)
	local lines = {}

	-- sort keys for deterministic output (topologically not required)
	local keys = {}
	for k in pairs(types) do table.insert(keys, k) end
	table.sort(keys)

	for _, k in ipairs(keys) do
		local node = types[k]
		local classLuau = node.className or "Instance"

		-- header
		table.insert(lines, ("export type %s = (() -> %s) & {"):format(k, classLuau))
		-- await signature: (self: Type) -> (InstanceClass, Type)
		table.insert(lines, ("\tawait: (self: %s) -> (%s, %s),"):format(k, classLuau, k))

		-- children
		-- sort children by name for deterministic order
		local childNames = {}
		for childName, _ in pairs(node.children) do table.insert(childNames, childName) end
		table.sort(childNames)
		for _, childName in ipairs(childNames) do
			local childType = node.children[childName]
			-- use sanitized property name as appears in instance (we keep original as key)
			local propName = sanitizeIdentifier(childName)
			table.insert(lines, ("\t%s: %s,"):format(propName, childType))
		end

		table.insert(lines, "}\n")
	end

	return lines
end

-- generate root Paths mapping
local function generatePathsRoot(types, rootInstances)
	local top = {}
	-- find top-level entries (parts length == 1)
	for typeName, info in pairs(types) do
		if info.parts and #info.parts == 1 then
			table.insert(top, { name = info.parts[1], type = typeName })
		end
	end
	table.sort(top, function(a,b) return a.name < b.name end)

	local lines = {}
	table.insert(lines, "export type Paths = {")
	for _, t in ipairs(top) do
		local propName = sanitizeIdentifier(t.name)
		table.insert(lines, ("\t%s: %s,"):format(propName, t.type))
	end
	table.insert(lines, "}\n")
	return lines
end

-- main: builds full file source using Template.Source as header
function GeneratePathsString()
	-- header lines from template
	local Lines = {}
	if Template and Template.Source then
		for _, l in ipairs(string.split(Template.Source, "\n")) do
			table.insert(Lines, l)
		end
	else
		table.insert(Lines, "-- auto-generated UIPaths")
	end

	-- collect nodes from StarterGui top-level children (remove clones)
	local roots = RemoveInstanceClones(StarterGui:GetChildren())
	local types = collectNodeTypes(roots)

	-- generate per-node types
	local typeLines = generateTypesLines(types)
	for _, l in ipairs(typeLines) do table.insert(Lines, l) end

	-- generate Paths root mapping
	local rootLines = generatePathsRoot(types, roots)
	for _, l in ipairs(rootLines) do table.insert(Lines, l) end

	-- final return (empty table) so ModuleScript can be required without runtime content
	table.insert(Lines, "return {}")
	return table.concat(Lines, "\n")
end

-- update/file write logic (uses ScriptEditorService)
function UpdateTypeRequest()
	if not TypesFolder then
		TypesFolder = GetTypesFolder()
		if not TypesFolder then
			return
		end
	end

	local PathsString = GeneratePathsString()
	local GenModule = GetGenModule()

	ScriptEditorService:UpdateSourceAsync(GenModule, function()
		return PathsString
	end)
end

-- watcher logic (keeps same as original, but triggers Generate on changes)
local UIPaths = {}

function UIPaths.Load(_janitor)
	_janitor:Add(StarterGui.DescendantRemoving:Connect(UpdateTypeRequest))
	_janitor:Add(StarterGui.DescendantAdded:Connect(function(Descendant)
		UpdateTypeRequest()
		Descendant:GetPropertyChangedSignal('Name'):Connect(UpdateTypeRequest)
		Descendant:GetPropertyChangedSignal('Parent'):Connect(UpdateTypeRequest)
	end))

	for _, Instance in StarterGui:GetDescendants() do
		_janitor:Add(Instance:GetPropertyChangedSignal('Name'):Connect(UpdateTypeRequest))
		_janitor:Add(Instance:GetPropertyChangedSignal('Parent'):Connect(UpdateTypeRequest))
	end

	UpdateTypeRequest()
end

return UIPaths
