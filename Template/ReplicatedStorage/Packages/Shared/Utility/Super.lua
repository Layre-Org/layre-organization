function Super(BaseClass: {[any]: any}, Class: {[any]: any})
	local meta = setmetatable({}, {
		__index = function(_, i)
			return BaseClass[i] or Class[i]
		end,
	})
	function meta.init(...)
		BaseClass = BaseClass.new(...)
		return setmetatable({}, {
			__index = function(_, i)
				return BaseClass[i] or Class[i]
			end,
		})
	end
	return meta
end

return Super
