local arrayMerge = require(script.utils.arrayMerge)
local dictionaryMerge = require(script.utils.dictionaryMerge)

local Table = {}

function Table:merge(table1: { any }, table2: { any })
	local isArray = if next(table1) ~= nil and next(table2) ~= nil then true else false

	if isArray then
		return arrayMerge(table1, table2)
	end

	return dictionaryMerge(table1, table2)
end

function Table:removeAmountFromArray(array: { any }, amount: number)
	for i = #array, 1, -1 do
		if amount <= 0 then
			break
		end

		table.remove(array, i)
		amount -= 1
	end

	return array
end

function Table:removeExcessFromArray(array: { any }, maxAmount: number)
	if #array <= maxAmount then
		return array
	end

	return self:removeAmountFromArray(array, #array - maxAmount)
end

function Table:getAmountFromArray(array: { any }, amount: number)
	local result = {}
	for i = #array, 1, -1 do
		if amount <= 0 then
			break
		end

		table.insert(result, array[i])
		amount -= 1
	end

	return result
end

return Table
