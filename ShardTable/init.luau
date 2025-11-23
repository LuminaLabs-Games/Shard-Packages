local arrayMerge = require(script.utils.arrayMerge)
local dictionaryMerge = require(script.utils.dictionaryMerge)

local Table = {}

function Table:merge(table1: { any }, table2: { any })
	-- Check if table1 is an array (has sequential numeric indices starting from 1)
	local isArray = #table1 > 0 and next(table1) == 1

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
