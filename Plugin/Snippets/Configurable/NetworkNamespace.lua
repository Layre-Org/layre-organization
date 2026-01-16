--</Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--</Packages
local ByteNet = require(ReplicatedStorage.Packages.Shared.Utility.ByteNet)

return ByteNet.defineNamespace('__name__', function()
	return {
		__cursor__
	}
end)