local function arrayMerge(table1, table2)
	local merged = {}

	for _, value in table1 do
		table.insert(merged, value)
	end

	for _, value in table2 do
		table.insert(merged, value)
	end

	return merged
end

return arrayMerge
