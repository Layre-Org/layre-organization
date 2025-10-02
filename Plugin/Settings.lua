local SETTING_KEY = "ServiceAutoComplete"

local Settings = {}

local plugin: Plugin = nil

local ServiceSortingTypes = {
	["Alphabetical"] = function(current, contender)
		return current > contender
	end,
	["Length"] = function(current, contender)
		return #current > #contender
	end,
	["InverseLength"] = function(current, contender)
		return #current < #contender
	end,
}

function Settings:CompareServices(a, b)
	local sortType = plugin:GetSetting(SETTING_KEY .. "_SortType")
	local sortFunction = ServiceSortingTypes[sortType] or ServiceSortingTypes["Alphabetical"]

	return sortFunction(a, b)
end

local function findSortType(input)
	local match = nil

	if #input > 1 then
		for name in ServiceSortingTypes do
			if string.match(string.lower(name), string.lower(input)) then
				match = name
			end
		end
	end

	return match
end

-- method to change sorting type exposed to the client
local function setSortType(input, secondInput)
	-- assume function was called using : operation
	if type(input) == "table" then
		input = secondInput
	end

	input = input or ""
	local newSortType = findSortType(tostring(input))

	if not newSortType then
		local sortTypesString = ""

		for sortType in ServiceSortingTypes do
			sortTypesString ..= `\n"{sortType}",`
		end

		warn(`Couldn't find sort type "{input}" \n Available sort types are: {sortTypesString}`)

		return "Couldn't find sort type"
	end

	plugin:SetSetting(SETTING_KEY .. "_SortType", newSortType)
	print("Set auto complete sort type to: " .. newSortType)

	return nil
end

-- expose to client
_G.ServiceSortType = setSortType
shared.ServiceSortType = setSortType

return function(pluginRef)
	plugin = pluginRef
	return Settings
end
