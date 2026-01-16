--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptEditorService = game:GetService("ScriptEditorService")

--</Misc
local TypesFolder = nil
local Template = script.Template
local Cache = {}

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Helper: remove comments and strings (simple but robust)
local function stripStringsAndComments(src)
	-- remove long comments and long strings first: --[[ ... ]] and [[ ... ]]
	src = src:gsub("%-%-%[%[.-%]%]", "") -- block comments
	src = src:gsub("%[%[.-%]%]", "")     -- block strings
	-- remove short comments
	src = src:gsub("%-%-.-\n", "\n")
	-- remove single-quoted and double-quoted strings
	src = src:gsub("%b''", "") 
	src = src:gsub('%b""', "")
	return src
end

-- tenta encontrar o identificador da tabela dentro do source:
local function detectStoreVarName(src, moduleName)
	-- procura "local X = {}" ou "X = {}" nas primeiras linhas
	for line in src:gmatch("[^\n]+\n?") do
		local localName = line:match("^%s*local%s+([%w_]+)%s*=%s*%{")
		if localName then return localName end
		local plainName = line:match("^%s*([%w_]+)%s*=%s*%{")
		if plainName then return plainName end
		-- se achar "local MyStore = {} -- module" etc, break cedo se passadas muitas linhas
	end
	-- fallback para nome do ModuleScript (não ideal se o source usa outro var)
	-- normalizar: não começar com número
	if moduleName and moduleName:match("^[%a_][%w_]*$") then
		return moduleName
	end
	return nil
end

local function splitParams(paramsStr)
	paramsStr = trim(paramsStr)
	if paramsStr == "" then return {} end
	local parts = {}
	for p in paramsStr:gmatch("[^,]+") do
		p = trim(p)
		if p ~= "" then table.insert(parts, p) end
	end
	return parts
end

local function splitParamsRaw(paramsStr)
	local t = {}
	if not paramsStr then return t end
	paramsStr = trim(paramsStr)
	if paramsStr == "" then return t end
	for token in paramsStr:gmatch("([^,]+)") do
		table.insert(t, trim(token))
	end
	return t
end

-- parseia um token como "Name: Type" ou "Name"
local function parseParamToken(token)
	-- token pode ser "Amount: number" ou "self" etc
	local name, typ = token:match("^([%w_]+)%s*:%s*(.+)$")
	if name then
		typ = trim(typ)
		return name, typ
	end
	-- sem anotação de tipo
	local nameOnly = token:match("^([%w_%.%?]+)$")
	if nameOnly then
		return nameOnly, nil
	end
	-- fallback
	return token, nil
end

-- extrai métodos ligados à tabela (usando varName) do source limpo
local function extractMethodsFromSource(src, varName)
	local methods = {}

	-- helper que registra a descoberta
	local function register(methodName, paramStr, implicitSelf)
		if not methodName then return end
		local rawTokens = splitParamsRaw(paramStr)
		local params = {} -- array of {name, type?}
		for _, tok in ipairs(rawTokens) do
			local name, typ = parseParamToken(tok)
			-- pular tokens vazios
			if name and name ~= "" then
				table.insert(params, { name = name, type = typ })
			end
		end
		methods[methodName] = { params = params, implicitSelf = implicitSelf == true }
	end

	-- patterns (aplicados apenas se varName existir)
	if varName then
		-- 1) function VAR:Method(params)
		for method, params in src:gmatch("function%s+" .. varName .. "%s*:%s*([%w_]+)%s*%(([^)]*)%)") do
			register(method, params, true)
		end

		-- 2) function VAR.Method(params)
		for method, params in src:gmatch("function%s+" .. varName .. "%s*%.%s*([%w_]+)%s*%(([^)]*)%)") do
			register(method, params, false)
		end

		-- 3) VAR.Method = function(params)
		for method, params in src:gmatch(varName .. "%s*%.%s*([%w_]+)%s*=%s*function%s*%(([^)]*)%)") do
			register(method, params, false)
		end

		-- 4) VAR['Method'] = function(params)  ou VAR["Method"] = function(params)
		for methodKey, params in src:gmatch(varName .. "%s*%[%s*['\"]([%w_]+)['\"]%s*%]%s*=%s*function%s*%(([^)]*)%)") do
			register(methodKey, params, false)
		end
	end

	return methods
end

-- monta a assinatura Luau-friendly a partir dos dados extraídos
local function buildSignature(storeName, methodInfo)
	local params = methodInfo.params or {}
	local parts = {}

	-- implicit self: sempre incluir self tipado como primeiro parâmetro
	if methodInfo.implicitSelf then
		table.insert(parts, ("self: {}"):format(storeName))
		-- agora os demais params (respeitando tipos)
		for _, p in ipairs(params) do
			table.insert(parts, (p.name .. ": " .. (p.type and p.type or "any")))
		end
	else
		-- não-implicit: ver se primeiro param é 'self'
		if #params >= 1 and params[1].name == "self" then
			-- substituir por typed self
			table.insert(parts, ("self: {}"):format(storeName))
			for i = 2, #params do
				local p = params[i]
				table.insert(parts, (p.name .. ": " .. (p.type and p.type or "any")))
			end
		else
			-- sem self: listar todos params normalmente
			for _, p in ipairs(params) do
				table.insert(parts, (p.name .. ": " .. (p.type and p.type or "any")))
			end
		end
	end

	-- montar string
	if #parts == 0 then
		-- sem params
		return ("() -> ()")
	end

	return ("(%s) -> ()"):format(table.concat(parts, ", "))
end

local function parseBlock(lines, startLine)
	local props = {}
	local i = startLine

	while i <= #lines do
		local line = trim(lines[i])

		if line:match("^}%s*[;,]?$") then
			return props, i
		end

		local name, typeStr = line:match("^([%w_]+)%s*:%s*(.+)")
		if name and typeStr then
			typeStr = trim(typeStr:gsub("[,;]%s*$", ""))

			if typeStr:sub(-1) == "{" then
				typeStr = trim(typeStr:sub(1, -2))

				local subProps
				subProps, i = parseBlock(lines, i + 1)

				props[name] = subProps
			else
				props[name] = typeStr
			end
		end

		i += 1
	end

	return props, i
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
	if Folder and Folder.Parent.Name == 'Shared' then
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
	local Module = GetGensFolder():FindFirstChild('UIScope')
	if not Module then
		Module = Instance.new('ModuleScript')
		Module.Name = 'UIScope'
		Module.Parent = GetGensFolder()
	end
	return Module
end

function GetComponentsFolder()
	local UIFolder = ReplicatedStorage:FindFirstChild('UI', true)
	if not UIFolder then return end
	
	local Components = UIFolder:FindFirstChild('Components')	
	return Components
end

function GetStoresFolder()
	local UIFolder = ReplicatedStorage:FindFirstChild('UI', true)
	if not UIFolder then return end

	local Stores = UIFolder:FindFirstChild('Stores')	
	return Stores
end

local function ExtractType(moduleScript: ModuleScript, type: string): { [string]: string }
	local source = moduleScript.Source
	if Cache[moduleScript] then
		source = Cache[moduleScript]
	end

	local lines = string.split(source, "\n")
	local startLine

	for i, line in ipairs(lines) do
		if line:match(`export%s+type%s+{type}%s*=%s*\{`) then
			startLine = i + 1
			break
		end
	end

	if not startLine then
		return {}
	end
	
	if lines[startLine - 1]:match('{}') then
		return {}
	end 

	local props
	props = parseBlock(lines, startLine)
	return props
end

local function FormatProps(props: table, indent: string): string
	local lines = {}
	local indentInner = indent .. "\t"

	for name, typeVal in props do
		if type(typeVal) == "table" then
			table.insert(lines, indentInner .. name .. ": {")
			table.insert(lines, FormatProps(typeVal, indentInner))
			table.insert(lines, indentInner .. "};")
		else
			if string.find(typeVal:lower(), 'scope') then
				typeVal = 'Scope'
			end
			table.insert(lines, indentInner .. name .. ": " .. typeVal .. ";")
		end
	end

	return table.concat(lines, "\n")
end

function GenerateComponentsTypeArray()
	local ComponentsFolder = GetComponentsFolder()
	if not ComponentsFolder then return {} end
	
	local Lines = {}
	local Components = RemoveInstanceClones(ComponentsFolder:GetDescendants())
	
	for _, Component in Components do
		if not Component:IsA('ModuleScript') then continue end
		local Props = ExtractType(Component, 'IProps')
		local Return = ExtractType(Component, 'IReturn')

		local IsEmpty = true
		for _ in Props do
			IsEmpty = false
			break
		end
		local ReturnIsEmpty = true
		for _ in Return do
			ReturnIsEmpty = false
			break
		end
		
		if not IsEmpty then
			table.insert(Lines, `\t{Component.Name}: (Scope: Scope) -> (Props: \{`)
			table.insert(Lines, FormatProps(Props, '\t'))

			if not ReturnIsEmpty then
				table.insert(Lines, '\t}) -> ({ ')
				table.insert(Lines, FormatProps(Return, '\t'))
				table.insert(Lines, '\t});')
			else
				table.insert(Lines, '\t}) -> ();')
			end
		else
			table.insert(Lines, `\t{Component.Name}: (Scope: Scope) -> (Props: \{}) -> ();`)
		end
	end
	
	return Lines
end

function GenerateStoresTypeArray()
	local StoresFolder = GetStoresFolder()
	if not StoresFolder then return {} end
	
	local Lines = {}
	local Stores = RemoveInstanceClones(StoresFolder:GetDescendants())
	
	for _, Store in Stores do
		if not Store:IsA('ModuleScript') then continue end
		local StoreType = ExtractType(Store, `I{Store.Name}Store`)
		
		local src = Store.Source or ""
		if Cache[Store] then
			src = Cache[Store]
		end
		local clean = stripStringsAndComments(src)
		local varName = detectStoreVarName(clean, Store.Name) -- tenta encontrar o "local X = {}" ou usa nome do ModuleScript
		local methods = extractMethodsFromSource(clean, varName)

		local IsEmpty = true
		for _ in StoreType do
			IsEmpty = false
			break
		end
		
		local methodNames = {}
		for name, info in pairs(methods) do
			if name ~= "Start" then
				table.insert(methodNames, name)
			end
		end
		table.sort(methodNames)

		if not IsEmpty or #methodNames > 0 then
			table.insert(Lines, `\t\t{Store.Name}: \{`)
			if not IsEmpty then
				table.insert(Lines, FormatProps(StoreType, '\t\t'))
			end
			for _, mname in ipairs(methodNames) do
				local info = methods[mname]
				local sig = buildSignature(Store.Name, info)
				-- se o método não tem self (sig começa com '(' e não 'self'), deixamos sem self
				-- caso contrário já incluímos self tipado
				-- colocar a linha com vírgula no final
				table.insert(Lines, ("\t\t\t%s: %s;"):format(mname, sig))
			end
			table.insert(Lines, '\t\t};')
		else
			table.insert(Lines, `\t\t{Store.Name}: \{};`)
		end
	end
	
	return Lines
end

function GeneratePathsString()
	local Lines = string.split(Template.Source, '\n')
	local ComponentsArray = GenerateComponentsTypeArray()
	local StoresArray = GenerateStoresTypeArray()
	
	local ComponentsLine = table.find(Lines, '--comps')
	table.remove(Lines, ComponentsLine)
	for i, Line in ComponentsArray do
		table.insert(Lines, ComponentsLine + i - 1, Line)
	end
	
	local StoresLine = table.find(Lines, '--stores')
	table.remove(Lines, StoresLine)
	table.insert(Lines, StoresLine, '\tStores: {')
	for i, Line in StoresArray do
		table.insert(Lines, StoresLine + i, Line)
	end
	table.insert(Lines, StoresLine + #StoresArray + 1, '\t\};')
	
	return table.concat(Lines, '\n')
end

function UpdateGeneratedRequest(ChangedScript: Script?)
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

local UIScope = {}

function UIScope.Load(_janitor)
	_janitor:Add(ScriptEditorService.TextDocumentDidChange:Connect(function(ScriptDocument, Changes)
		if ScriptDocument:IsCommandBar() then return end
		
		local ComponentsFolder = GetComponentsFolder()
		local StoresFolder = GetStoresFolder()
		if not ComponentsFolder and not StoresFolder then return end

		local Script = ScriptDocument:GetScript()
		if not Script:IsDescendantOf(ComponentsFolder) and not Script:IsDescendantOf(StoresFolder) then return end

		table.clear(Cache)
		Cache[Script] = ScriptDocument:GetText()
		
		UpdateGeneratedRequest(Script)
	end))

	local ComponentsFolder = GetComponentsFolder()
	if ComponentsFolder then 
		_janitor:Add(ComponentsFolder.DescendantRemoving:Connect(UpdateGeneratedRequest))
		_janitor:Add(ComponentsFolder.DescendantAdded:Connect(function(Descendant)
			UpdateGeneratedRequest()
			_janitor:Add(Descendant:GetPropertyChangedSignal('Name'):Connect(UpdateGeneratedRequest))
			_janitor:Add(Descendant:GetPropertyChangedSignal('Parent'):Connect(UpdateGeneratedRequest))
		end))

		for _, Instance in ComponentsFolder:GetDescendants() do
			_janitor:Add(Instance:GetPropertyChangedSignal('Name'):Connect(UpdateGeneratedRequest))
			_janitor:Add(Instance:GetPropertyChangedSignal('Parent'):Connect(UpdateGeneratedRequest))
		end
	end

	local StoresFolder = GetStoresFolder()
	if StoresFolder then 
		_janitor:Add(StoresFolder.DescendantRemoving:Connect(UpdateGeneratedRequest))
		_janitor:Add(StoresFolder.DescendantAdded:Connect(function(Descendant)
			UpdateGeneratedRequest()
			_janitor:Add(Descendant:GetPropertyChangedSignal('Name'):Connect(UpdateGeneratedRequest))
			_janitor:Add(Descendant:GetPropertyChangedSignal('Parent'):Connect(UpdateGeneratedRequest))
		end))

		for _, Instance in StoresFolder:GetDescendants() do
			_janitor:Add(Instance:GetPropertyChangedSignal('Name'):Connect(UpdateGeneratedRequest))
			_janitor:Add(Instance:GetPropertyChangedSignal('Parent'):Connect(UpdateGeneratedRequest))
		end
	end

	UpdateGeneratedRequest()
end

return UIScope
