local function getNestedValue(table, path)
    local current = table
    for _, key in path do
        current = current[key]
        if current == nil then
            return nil
        end
    end
    return current
end

return function(replica, path, callback)
	callback(getNestedValue(replica.Data, path))
	replica:OnSet(path, callback)
end