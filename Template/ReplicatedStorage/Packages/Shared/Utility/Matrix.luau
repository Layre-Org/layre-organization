local function deepClone(t: {[any]: any})
	local newT = {}
	for k, v in t do
		newT[k] = typeof(v) == 'table' and table.deepClone(v) or v
	end
	return newT
end

local MatrixConstructor = {}

local MatrixClass = {}
MatrixClass.__index = MatrixClass

function MatrixConstructor.new<T>(rows: number, columns: number, defaultValue: T)
	if defaultValue ~= false then
		defaultValue = defaultValue or 0
	end
	local self = setmetatable({}, MatrixClass)
	
	self.value = {}
	self._defaultValue = defaultValue
	
	self.rows = rows
	self.cols = columns
	
	for i = 1, rows do
		self.value[i] = {}
		for j = 1, columns do
			self.value[i][j] = typeof(defaultValue) == 'table' and deepClone(defaultValue) or defaultValue
		end
	end

	return self
end

function MatrixConstructor.fromTable(t: {[number]: {}})
	local rows = #t
	local columns = #t[1]
	
	local self = MatrixConstructor.new(rows, columns)
	
	for i, line in t do
		for j, value in line do
			self:set(i, j, value)
		end
		if #line < columns then
			for k = #line+1, columns do
				self:set(i, k, 0)
			end
		end
	end
	
	return self
end


function MatrixClass:resize(rows: number, columns: number)
	rows = rows or self.rows
	columns = columns or self.cols

	if rows < self.rows then
		self.value = self:lines(1, rows)
	else
		if rows ~= self.rows then
			for i = self.rows+1, rows do
				self.value[i] = {}
				for j = 1, columns do
					self.value[i][j] = self._defaultValue
				end
			end
		end
	end

	if columns < self.cols then
		self.value = self:columns(1, columns)
	else
		if columns ~= self.cols then
			for i = 1, #self.value do
				for j = self.cols+1, columns do
					self.value[i][j] = self._defaultValue
				end
			end
		end
	end

	self.rows = rows
	self.cols = columns
end

function MatrixClass:at(i: number, j: number)
	return j and self.value[i][j] or self.value[i]
end

function MatrixClass:set<T>(i: number, j: number, value: T)
	self.value[i][j] = value
end

function MatrixClass:lines(min: number, max: number)
	min = min or 1
	max = max or #self.value

	local lines = {}
	for i = min, max do
		lines[i] = self.value[i]
	end

	return lines
end

function MatrixClass:head(n: number)
	return self:lines(1, n)
end

function MatrixClass:tail(n: number)
	return self:lines(#self.value - n + 1, #self.value)
end

function MatrixClass:columns(min: number, max: number)
	min = min or 1
	max = max or #self.value[1]

	local columns = {}
	for i = 1, self.rows do
		columns[i] = {}
		for j = min, max do
			columns[i][j] = self.value[i][j]
		end
	end

	return columns
end

function MatrixClass:iterate(callback: (i: number, j: number, value: any) -> ())
	local br = false
	for i = 1, self.rows do
		if br == true then break end
		for j = 1, self.cols do
			br = callback(i, j, self.value[i][j])
			if br == true then break end
		end
	end
end

return MatrixConstructor
