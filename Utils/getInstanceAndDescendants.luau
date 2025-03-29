return function(instance)
	local result = { instance }

	for _, descendant in pairs(instance:GetDescendants()) do
		table.insert(result, descendant)
	end

	return result
end
