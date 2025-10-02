--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

--</Packages
local Promise = require(ReplicatedStorage.Packages.Shared.Utility.Promise)
local UIPaths = require(ReplicatedStorage.Packages.Shared.Types.__generated.UIPaths)

local function deepWaitForChild(root, pathTree)
	local instance = nil

	if #pathTree == 1 then
		return root:WaitForChild(pathTree[1], 20)
	end

	instance = root:WaitForChild(pathTree[1], 20)
	table.remove(pathTree, 1)
	return deepWaitForChild(instance, pathTree)
end

local function deepFindFirstChild(root, pathTree)
	local instance = nil

	if #pathTree == 1 then
		return root:FindFirstChild(pathTree[1])
	end

	instance = root:FindFirstChild(pathTree[1])
	if not instance then
		return nil
	end

	table.remove(pathTree, 1)
	return deepFindFirstChild(instance, pathTree)
end

local function makeLazy(root, pathTree)
	local proxy = {}
	setmetatable(proxy, {
		__index = function(self, index)
			if pathTree and index == 'await' then
				local promise = Promise.new(function(Resolve)
					local instance = deepWaitForChild(root, table.clone(pathTree))
					table.clear(pathTree)
					Resolve(instance)
				end)

				return function()
					local sucess, result = promise:await()
					if not sucess then
						return
					end
					return result, makeLazy(result)
				end 
			end

			pathTree = pathTree or {}
			table.insert(pathTree, index)

			local child = root:FindFirstChild(index)
			if not child then
				return makeLazy(root, pathTree)
			end

			return makeLazy(root, pathTree)
		end,

		__tostring = function()
			if not pathTree then
				-- if called "Paths" table
				return 'UIPaths'
			end

			local instance = deepFindFirstChild(root, pathTree)
			local pathString = table.concat(pathTree, '.')
			table.clear(pathTree)

			if not instance then
				warn(`{pathString} not found. Did you forget to call ()?`)
				return 'UIPaths'
			end

			return tostring(instance)
		end,

		__call = function(_, ...) 
			if not pathTree then
				-- if called "Paths" table
				return nil
			end

			local instance = deepFindFirstChild(root, pathTree)
			table.clear(pathTree)
			return instance
		end,
	})

	return proxy
end

local Paths = makeLazy(PlayerGui)

return Paths :: UIPaths.Paths