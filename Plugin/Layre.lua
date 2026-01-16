--</Services
local ScriptEditorService = game:GetService("ScriptEditorService")
local InsertService = game:GetService('InsertService')
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StudioService = game:GetService("StudioService")
local SelectionService = game:GetService('Selection')

--</Toolbar
local Toolbar = plugin:CreateToolbar('Layre')
local SetupButton = Toolbar:CreateButton('Setup org', 'Setups the Layre Organization in the game', 'rbxassetid://1507949215')
local UpdateButton = Toolbar:CreateButton('Update org', 'Updates the Layre Organization in your place to the latest version without losing your code', 'rbxassetid://1507949215')

local OrgId = 72555432759630
local LocalUserId = StudioService:GetUserId()

local Services = {
	RS = ReplicatedStorage,
	SSS = ServerScriptService
}

SetupButton.Click:Connect(function()
	SetupButton:SetActive(false)

	if ReplicatedStorage:FindFirstChild('Packages') or ServerScriptService:FindFirstChild('Core') then return end
	local success, Asset = pcall(function() return InsertService:LoadAsset(OrgId) end)
	if not success then warn('Error on inserting the asset') return end
	for _, ServiceFolder in Asset:FindFirstChildOfClass('Model'):GetChildren() do
		for _, Folder in ServiceFolder:GetChildren() do
			Folder.Parent = Services[ServiceFolder.Name]
		end
	end
	Asset:Destroy()
end)

UpdateButton.Click:Connect(function()
	UpdateButton:SetActive(false)
end)


--</AutoComplete
local Lexer = require(script.lexer)
local Settings = require(script.Settings)(plugin)
local Snippets = require(script.Snippets)
local Creation = require(script.Creation)

-- service names is not ideal but causes security checks if not used so :/
local ServiceNames = {}

local PROCESS_NAME = "Layre Plugin"
local LEARN_MORE_LINK = "https://create.roblox.com/docs/reference/engine/classes/"
local SERVICE_DEF = 'local %s = game:GetService("%s")\n'

local CHECKED_GLOBAL_VARIABLES = {
	print = Enum.CompletionItemKind.Function,
	_G = Enum.CompletionItemKind.Variable,
	_VERSION = Enum.CompletionItemKind.Variable,
	Vector3 = Enum.CompletionItemKind.Struct,
	CFrame = Enum.CompletionItemKind.Struct,
}

local CompletingDoc = nil
local CompleteingLine = 0
local CompleteingWordStart = 0

type Request = {
	position: {
		line: number,
		character: number,
	},
	textDocument: {
		document: ScriptDocument?,
		script: LuaSourceContainer?,
	},
}

type ResponseItem = {
	label: string,
	kind: Enum.CompletionItemKind?,
	tags: { Enum.CompletionItemTag }?,
	detail: string?,
	documentation: {
		value: string,
	}?,
	overloads: number?,
	learnMoreLink: string?,
	codeSample: string?,
	preselect: boolean?,
	textEdit: {
		newText: string,
		replace: {
			start: { line: number, character: number },
			["end"]: { line: number, character: number },
		},
	}?,
}

type Response = {
	items: {
		[number]: ResponseItem,
	},
}

type DocChanges = {
	range: { start: { line: number, character: number }, ["end"]: { line: number, character: number } },
	text: string,
}

local function startswith(str, prefix)
	return string.sub(str, 1, #prefix) == prefix
end


local function isService(instance)
	-- avoid unnamed instances
	if instance.Name == "Instance" then
		return false
	end

	-- it shouldn't be possible to create another service
	-- prevents highest level user made instances from appearing
	-- new instance should be cleared by garbage collector
	local success = pcall(function()
		return instance.new(instance.ClassName)
	end)

	if success then
		return
	end

	return game:GetService(instance.ClassName)
end

local function checkIfService(instance)
	local success, validService = pcall(isService, instance)
	if success and validService then
		ServiceNames[instance.ClassName] = true
	else
		pcall(function()
			ServiceNames[instance.ClassName] = false
		end)
	end
end

-- used in a different function so it can return without ruining the callback
local function addServiceAutocomplete(request: Request, response: Response)
	local doc = request.textDocument.document

	local req = doc:GetLine(request.position.line)
	req = string.sub(req, 1, request.position.character - 1)

	local requestedWord = string.match(req, "[%w]+$")

	-- no text found
	if not requestedWord then
		return
	end

	local potentialMatches = {}

	for serviceName in ServiceNames do
		if string.sub(string.lower(serviceName), 1, #requestedWord) == string.lower(requestedWord) then
			potentialMatches[serviceName] = true
		end
	end

	for _, v in response.items do
		-- already exists as an autofill
		-- likely that its defined
		if potentialMatches[v.label] then
			-- append a leanMoreLink to the builtin one (this is embarassing LOL)
			v.learnMoreLink = LEARN_MORE_LINK .. v.label
			potentialMatches[v.label] = nil
		end
	end

	for serviceName in potentialMatches do
		local responseItem: ResponseItem = {
			label = serviceName,
			detail = "Get Service: " .. serviceName,
			learnMoreLink = LEARN_MORE_LINK .. serviceName,
		}

		responseItem.textEdit = {
			newText = serviceName,
			replace = {
				start = {
					line = request.position.line,
					character = request.position.character - #requestedWord,
				},
				["end"] = {
					line = request.position.line,
					character = request.position.character,
				},
			},
		}

		table.insert(response.items, responseItem)
	end

	-- don't update if theres no matches
	if next(potentialMatches) == nil then
		return
	end

	CompletingDoc = doc
	CompleteingLine = request.position.line
	CompleteingWordStart = string.find(req, requestedWord, #req - #requestedWord)
end

local function getFullScript(doc: ScriptDocument)
	local fullScriptString = ""
	local rawSource = {}

	for line = 1, doc:GetLineCount() do
		local lineCode = doc:GetLine(line)
		if lineCode == nil then
			continue
		end

		rawSource[line] = lineCode

		lineCode ..= "\n"
		fullScriptString ..= lineCode
	end

	return fullScriptString, rawSource
end

local cachedTokens = {}
local function getAllTokens(doc: ScriptDocument)
	local fullScriptString, rawSource = getFullScript(doc)

	local cached = cachedTokens[rawSource]
	if cached then
		return cached
	end

	local currentLine = 1
	local currentCharacter = 1

	-- recursively find the tokens in order
	local function getLine(token)
		local lineCode = rawSource[currentLine]
		assert(lineCode, "couldn't find code to compare against")

		local tokenStart, tokenEnd = string.find(lineCode, token, currentCharacter, true)

		if tokenStart and tokenEnd then
			currentCharacter = tokenEnd + 1
			return currentLine, tokenStart, tokenEnd
		else
			currentLine += 1
			currentCharacter = 1

			return getLine(token)
		end
	end

	local quickScan = Lexer.scan(fullScriptString)
	local tokens = {}

	repeat
		local type, token = quickScan()
		if not type then
			continue
		end

		if string.match(token, "\n") then
			token = string.sub(token, 1, #token - 1)
		end

		-- sometimes needs to happen twice
		if string.match(token, "\n") then
			token = string.sub(token, 1, #token - 1)
		end

		local seperatedLines = string.split(token, "\n")
		local endLine = nil

		local line, startChar, endChar

		for _, splitToken in seperatedLines do
			if not startChar then
				line, startChar, endChar = getLine(splitToken)
				endLine = line
			else
				endLine, _, endChar = getLine(splitToken)
			end
		end

		table.insert(tokens, {
			type = type,
			value = token,
			startLine = line,
			endLine = endLine,
			startChar = startChar,
			endChar = endChar,
		})
	until not type

	cachedTokens[rawSource] = tokens
	task.delay(10, function()
		cachedTokens[rawSource] = nil
	end)

	return tokens
end

local function findNonCommentLine(doc: ScriptDocument)
	local lineAfterComments = 0

	for _, token in getAllTokens(doc) do
		if token.type ~= "comment" then
			break
		end

		lineAfterComments = token.endLine + 2
	end

	return lineAfterComments
end

local function findAllServices(doc: ScriptDocument, startLine: number?, endLine): { [string]: number }?
	startLine = startLine or 0

	local services = {
		--[ServiceName] = lineNumber
	}

	for _, token in getAllTokens(doc) do
		if token.startLine < startLine or token.endLine > endLine then
			continue
		end

		if token.type == "string" then
			local cleanValue = string.match(token.value, "%w+")
			if not ServiceNames[cleanValue] then
				continue
			end

			services[cleanValue] = token.endLine
		end
	end

	return services
end

local function AddService(doc, change, serviceName)
	if not ServiceNames[serviceName] or #serviceName < 3 then
		return
	end

	CompleteingLine = 0
	CompleteingWordStart = 0

	local firstServiceLine = math.huge
	local lastServiceLine = 1
	local lineToComplete = 1
	local moved = false

	local existingServices = findAllServices(doc, nil, change.range["end"].line - 1)

	if next(existingServices) then
		for otherService, line in existingServices do
			-- hit a bug where its trying to duplicate a service
			if otherService == serviceName then
				return lastServiceLine
			end

			if line >= lineToComplete then
				-- sorting operator
				if Settings:CompareServices(serviceName, otherService) then
					lineToComplete = line
					moved = true
				end

				lastServiceLine = line
			end

			if line < firstServiceLine then
				firstServiceLine = line
			end
		end

		-- caused too many problems
		for _, line in existingServices do
			if line > lastServiceLine then
				lastServiceLine = line
			end
		end

		-- hasn't changed default to the lowest
		if lineToComplete == 1 and not moved then
			lineToComplete = firstServiceLine - 1
		end

		lineToComplete += 1
		lastServiceLine += 1
	else
		lineToComplete = 1--findNonCommentLine(doc)
	end
	
	if lastServiceLine == 1 then
		lastServiceLine = lineToComplete + 1
	end

	local docLineCount = doc:GetLineCount()
	if lastServiceLine >= docLineCount then
		lastServiceLine = docLineCount
	end

	if doc:GetLine(lastServiceLine) ~= "" then
		doc:EditTextAsync("\n", lastServiceLine, 1, 0, 0)
	end

	if lineToComplete < 1 then
		lineToComplete = 1
	end
	local serviceRequire = string.format(SERVICE_DEF, serviceName, serviceName)
	if firstServiceLine == math.huge then
		if not string.find(doc:GetLine(1), '--</Services') then
			doc:EditTextAsync('--</Services\n', 1, 1, 0, 0)
			serviceRequire ..= '\n'
			lastServiceLine = 2
		end
		lineToComplete = 2
	elseif firstServiceLine == 1 then
		doc:EditTextAsync('--</Services\n', 1, 1, 0, 0)
		lineToComplete += 1
		lastServiceLine = 2
	else
		if not string.find(doc:GetLine(firstServiceLine-1), '--</Services') then
			doc:EditTextAsync('--</Services\n', firstServiceLine-1, 1, 0, 0)
			lineToComplete += 1
			lastServiceLine += 1
		end
	end
	doc:EditTextAsync(serviceRequire, lineToComplete, 1, 0, 0)
	return lastServiceLine
end

local function searchForPackages(doc, startLine)
	for i = startLine, math.min(startLine + 10, doc:GetLineCount()) do
		local line = doc:GetLine(i)
		if startswith(line, '--</Packages') then
			return i
		end
	end
end

local function checkIfExists(doc, startLine, text)
	for i = startLine, math.min(startLine + 10, doc:GetLineCount()) do
		local line = doc:GetLine(i)
		if line == text then
			return true
		end
	end
	return false
end

local function findLineWith(doc, text)
	for i = 1, doc:GetLineCount() do
		local line = doc:GetLine(i)
		if string.find(line, text) then return i, line end	
	end
end

local function processDocChanges(doc: ScriptDocument, change: DocChanges)
	if startswith(change.text, '@AutoImport@') then
		local parts = string.split(change.text, ':')
		local name = parts[2]
		local path = parts[3]
		local className = parts[4]
		local id = parts[5]

		if tonumber(id) ~= LocalUserId then
			return
		end
		
		name = string.gsub(name, 'UIController', '')
		
		local requireText = `local {name} = ` .. (className == 'Folder' and path or `require({path})`)
		
		doc:EditTextAsync(name, change.range.start.line, change.range.start.character, change.range.start.line, change.range.start.character + #change.text)
		local lastServiceLine = AddService(doc, change, string.split(path, '.')[1])
		local packagesLine = searchForPackages(doc, lastServiceLine+1)
		local exists = checkIfExists(doc, lastServiceLine+1, requireText)
		if exists then return end
		if packagesLine then
			doc:EditTextAsync(requireText..'\n', packagesLine+1, 1, 0, 0)
		else
			doc:EditTextAsync('\n--</Packages\n'..requireText..'\n', lastServiceLine+1, 1, 0, 0)
		end
	elseif string.find(change.text, '__cursor__') and not string.find(change.text, "'__cursor__'") then
		local line, lineText = findLineWith(doc, '__cursor__')
		local index = string.find(lineText, '__cursor__')
		doc:EditTextAsync('', line, index, line, index+10)
		doc:RequestSetSelectionAsync(line, index)
	else
		if change.range.start.character ~= CompleteingWordStart and change.range.start.line ~= CompleteingLine then
			return
		end

		local serviceName = change.text
		AddService(doc, change, serviceName)
	end
end

function getInstanceByFullName(fullName)
	local segments = string.split(fullName, ".")
	local currentInstance = game

	for _, name in ipairs(segments) do
		local foundChild = currentInstance:FindFirstChild(name)
		if foundChild then
			currentInstance = foundChild
		else
			--warn("Could not find instance segment: " .. name .. " in path: " .. fullName)
			return nil
		end
	end

	return currentInstance
end

local function processCmdChanges(doc: ScriptDocument, change: DocChanges)
	if startswith(change.text, '@Open@') then
		local parts = string.split(change.text, ':')
		local name = parts[2]
		local path = parts[3]
		local module = getInstanceByFullName(path)
		ScriptEditorService:OpenScriptDocumentAsync(module)
		SelectionService:Set({module})
	elseif startswith(change.text, '@Create@') then
		local parts = string.split(change.text, ':')
		local name = parts[2]
		local path = parts[3]
		local parent = getInstanceByFullName(path)
		local module = Instance.new('ModuleScript', parent)
		module.Name = name
		ScriptEditorService:OpenScriptDocumentAsync(module)
		SelectionService:Set({module})
	end
end

local function onDocChanged(doc: ScriptDocument, changed: { DocChanges })
	if doc ~= CompletingDoc then
		return
	end
	
	for _, change in changed do
		if doc:IsCommandBar() then
			processCmdChanges(doc, change)
 		else
			processDocChanges(doc, change)
		end
	end
end

local function addSnippetsAutoComplete(request: Request, response: Response)
	local doc = request.textDocument.document
	local line = doc:GetLine(request.position.line)

	local split = string.split(line, '@')	
	local name = string.match(split[1], "[%w]+$") -- get last word
	local snippet = split[2]
	
	if not name or not snippet then
		return
	end
	
	for modName, source in Snippets.Configurable do
		if string.sub(modName:lower(), 1, #snippet) == snippet:lower() then
			local item = {
				label = modName,
				textEdit = {
					newText = string.gsub(source, '__name__', name), 
					replace = {
						start = {
							line = request.position.line,
							character = request.position.character - #name - #snippet - 1
						},
						["end"] = {
							line = request.position.line,
							character = request.position.character
						}
					}
				}
			}
			table.insert(response.items, item)
		end
	end	
end

local function findInServices(Text)
	Text = Text:lower()
	local matches = {}
	for _, Instance: Instance in ReplicatedStorage:GetDescendants() do
		if Instance:IsA('ModuleScript') or Instance:IsA('Folder') and (startswith(Instance.Name:lower(), Text) or Text == '') then
			if ReplicatedStorage:FindFirstChild('Packages') then
				if Instance:IsDescendantOf(ReplicatedStorage.Packages.Shared.Utility) and Instance.Parent.Name ~= 'Utility' and Instance.Parent:IsA('ModuleScript') then continue end
			end
			table.insert(matches, Instance.ClassName .. ':' .. Instance:GetFullName())
		end
	end
	for _, Instance: Instance in ServerScriptService:GetDescendants() do
		if Instance:IsA('ModuleScript') or Instance:IsA('Folder') and (startswith(Instance.Name:lower(), Text) or Text == '') then
			table.insert(matches, Instance.ClassName .. ':' .. Instance:GetFullName())
		end
	end
	return matches
end

local function removeSymbols(text, ...)
	local args = {...}
	for _, arg in args do
		text = string.split(text, arg)[1]
	end
	return text
end

local UIControllers
local function addAutoImport(request: Request, response: Response)
	local doc = request.textDocument.document
	local line = doc:GetLine(request.position.line)
	
	local pattern = string.sub(line, string.find(line, '@')+1)
	pattern = removeSymbols(pattern, ' ', '.', ',', ':', ';', '	', '[', '(', ')', ']')
	local services = findInServices(pattern)
	
	if not UIControllers then
		UIControllers = ReplicatedStorage:FindFirstChild('UIControllers', true)
	end
	
	for _, data in services do
		local className, path = table.unpack(string.split(data, ':'))
		local parts = string.split(path, '.')
		local name = parts[#parts]
		local parentName = parts[#parts-1]
		local displayName = name
		
		local inst: Instance = getInstanceByFullName(path)
		if UIControllers and inst:IsDescendantOf(UIControllers) then
			displayName ..= 'UIController'
		end

		if parentName == 'Packets' or parentName == 'Settings' then
			displayName ..= parentName
		end
		
		local item = {
			label = displayName,
			detail = `Imports {name} from folder {parentName} with name {displayName} - {className}`,
			textEdit = {
				newText = `@AutoImport@:{displayName}:{path}:{className}:{LocalUserId}`,
				replace = {
					start = {
						line = request.position.line,
						character = string.find(line, '@')
					},
					["end"] = {
						line = request.position.line,
						character = string.find(line, '@') + #pattern + 1
					}
				}
			}
		}
		
		table.insert(response.items, item)
	end
	
	CompletingDoc = doc
end

local function lstrip(str)
	return string.gsub(str, "^%s+", "")
end

local function updateResponse(request: Request, response: Response)
	local doc = request.textDocument.document
	local line = doc:GetLine(request.position.line)
	
	local index = string.find(line, '@')
	if index then
		table.clear(response.items)
		local symbols = {' ', '.', ',', ':', ';', '	', '[', '(', ')', ']'}
		if startswith(line, '@') or table.find(symbols, string.sub(line, index-1, index-1)) then
			addAutoImport(request, response)
		else
			if string.sub(line, index-1, index-1) == ' ' then
				addAutoImport(request, response)
			else
				addSnippetsAutoComplete(request, response)
			end
		end
	else
		for _, v in response.items do
			local expectedKind = CHECKED_GLOBAL_VARIABLES[v.label]
			if expectedKind then
				if v.kind ~= expectedKind then
					continue
				end

				CompleteingLine = 0
				CompleteingWordStart = 0
				addServiceAutocomplete(request, response)
				break
			end
		end
	end
end

local function cmdBarFindInServices(Text)
	Text = Text:lower()
	local matches = {}
	
	for _, Instance: Instance in ReplicatedStorage:GetDescendants() do
		if Instance:IsA('ModuleScript') or Instance:IsA('Script') or Instance:IsA('LocalScript') and (startswith(Instance.Name:lower(), Text) or Text == '') then
			if ReplicatedStorage:FindFirstChild('Packages') then
				if Instance:IsDescendantOf(ReplicatedStorage.Packages.Shared.Utility) and Instance.Parent.Name ~= 'Utility' and Instance.Parent:IsA('ModuleScript') then continue end
			end
			table.insert(matches, Instance.ClassName .. ':' .. Instance:GetFullName())
		end
	end
	
	for _, Instance: Instance in StarterPlayer:GetDescendants() do
		if Instance:IsA('ModuleScript') or Instance:IsA('Script') or Instance:IsA('LocalScript') and (startswith(Instance.Name:lower(), Text) or Text == '') then
			table.insert(matches, Instance.ClassName .. ':' .. Instance:GetFullName())
		end
	end
	
	for _, Instance: Instance in ReplicatedFirst:GetDescendants() do
		if Instance:IsA('ModuleScript') or Instance:IsA('Script') or Instance:IsA('LocalScript') and (startswith(Instance.Name:lower(), Text) or Text == '') then
			table.insert(matches, Instance.ClassName .. ':' .. Instance:GetFullName())
		end
	end
	
	for _, Instance: Instance in ServerScriptService:GetDescendants() do
		if Instance:IsA('ModuleScript') or Instance:IsA('Script') and (startswith(Instance.Name:lower(), Text) or Text == '') then
			table.insert(matches, Instance.ClassName .. ':' .. Instance:GetFullName())
		end
	end
	
	for _, Instance: Instance in ServerStorage:GetDescendants() do
		if Instance:IsA('ModuleScript') or Instance:IsA('Script') and (startswith(Instance.Name:lower(), Text) or Text == '') then
			table.insert(matches, Instance.ClassName .. ':' .. Instance:GetFullName())
		end
	end
	
	return matches
end

local function addCmdBarOpen(request: Request, response: Response)
	local doc = request.textDocument.document
	local line = doc:GetLine(request.position.line)

	local pattern = string.sub(line, string.find(line, '@')+1)
	pattern = removeSymbols(pattern, ' ', '.', ',', ':', ';', '	', '[', '(', ')', ']')
	
	local services = cmdBarFindInServices(pattern)

	if not UIControllers then
		UIControllers = ReplicatedStorage:FindFirstChild('UIControllers', true)
	end

	for _, data in services do
		local className, path = table.unpack(string.split(data, ':'))
		local parts = string.split(path, '.')
		local name = parts[#parts]
		local parentName = parts[#parts-1]
		local displayName = name
		
		local inst: Instance = getInstanceByFullName(path)
		if UIControllers and inst and inst:IsDescendantOf(UIControllers) then
			displayName ..= 'UIController'
		end

		if parentName == 'Packets' or parentName == 'Settings' then
			displayName ..= parentName
		end

		local item = {
			label = displayName,
			detail = `Open {name} from folder {parentName} with name {displayName} - {className}`,
			textEdit = {
				newText = `@Open@:{displayName}:{path}:{className}`,
				replace = {
					start = {
						line = request.position.line,
						character = string.find(line, '@')
					},
					["end"] = {
						line = request.position.line,
						character = string.find(line, '@') + #pattern + 1
					}
				}
			}
		}

		table.insert(response.items, item)
	end

	CompletingDoc = doc
end

local function addCmdBarCreate(request: Request, response: Response)
	local doc = request.textDocument.document
	local line = doc:GetLine(request.position.line)


	local split = string.split(line, '@+')	
	local name = string.match(split[1], "[%w]+$") -- get last word
	local targetPath = split[2]

	if not name or not targetPath then
		return
	end
	

	local matches = {}
	for pathName, path in Creation.Paths do
		if string.sub(pathName:lower(), 1, #targetPath) == targetPath:lower() then
			matches[pathName] = path
		end
	end

	for pathName, path in matches do
		local item = {
			label = pathName,
			detail = `Create a Module in in path: {pathName}`,
			textEdit = {
				newText = `@Create@:{name .. ((pathName == 'Managers' or pathName == 'Controllers') and string.sub(pathName, 1, #pathName-1) or '')}:{path}`,
				replace = {
					start = {
						line = request.position.line,
						character = string.find(line, '@+') - #name
					},
					["end"] = {
						line = request.position.line,
						character = string.find(line, '@+') + #targetPath + 2
					}
				}
			}
		}

		table.insert(response.items, item)
	end

	CompletingDoc = doc
end

local function updateCmdBarResponse(request: Request, response: Response)
	local doc = request.textDocument.document
	local line = doc:GetLine(request.position.line)

	if string.find(line, '@%+') then
		table.clear(response.items)
		addCmdBarCreate(request, response)
	elseif string.find(line, '@') then
		table.clear(response.items)
		addCmdBarOpen(request, response)
	end
end

local function completionRequested(request: Request, response: Response)
	local doc = request.textDocument.document
	if not doc then
		return response
	end
	
	if doc:IsCommandBar() then
		updateCmdBarResponse(request, response)
		
		return response
	end

	-- shares the response to another function
	updateResponse(request, response)

	return response
end

-- prevent potential overlap for some reason errors if one doesn't exist weird api choice but ok-
pcall(ScriptEditorService.DeregisterAutocompleteCallback, ScriptEditorService, PROCESS_NAME)
ScriptEditorService:RegisterAutocompleteCallback(PROCESS_NAME, 10, completionRequested)

-- roblox will throw an output error and tell the user to enable script injection in settings if this fails to connect
ScriptEditorService.TextDocumentDidChange:Connect(onDocChanged)

game.ChildAdded:Connect(checkIfService)
game.ChildRemoved:Connect(checkIfService)
for _, v in game:GetChildren() do
	checkIfService(v)
end

local TypesGenerator = require(script.TypesGenerator)
TypesGenerator.Load()

plugin.Unloading:Connect(function()
	pcall(ScriptEditorService.DeregisterAutocompleteCallback, ScriptEditorService, PROCESS_NAME)
	TypesGenerator.Unload()
end)