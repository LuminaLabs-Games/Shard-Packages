local function dictionaryMerge(table1, table2)
	local merged = {}

	for key, value in table1 do
		merged[key] = value
	end

	for key, value in table2 do
		if type(value) == "table" and type(merged[key]) == "table" then
			merged[key] = dictionaryMerge(merged[key], value)
		else
			merged[key] = value
		end
	end

	return merged
end

return dictionaryMerge
