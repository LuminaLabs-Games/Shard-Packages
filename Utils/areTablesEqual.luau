return function(table1, table2)
	if #table1 ~= #table2 then
		return false
	end
	for i = 1, #table1 do
		if table1[i] ~= table2[i] then
			return false
		end
	end
	return true
end
