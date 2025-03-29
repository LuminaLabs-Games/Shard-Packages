local function render3dGrid(minPart: BasePart, maxPart: BasePart, step: number)
	local CFrames = {}

	local minCFrame = minPart:GetPivot()
	local maxCFrame = maxPart:GetPivot()

	local xMax = math.abs((maxCFrame.Position.X - minCFrame.Position.X) / step)
	local yMax = math.abs((maxCFrame.Position.Y - minCFrame.Position.Y) / step)
	local zMax = math.abs((maxCFrame.Position.Z - minCFrame.Position.Z) / step)

	if minPart.Orientation.Y < 180 then -- fixes z and x axis being flipped
		local x = xMax
		xMax = zMax
		zMax = x
	end

	for y = 0, yMax do
		for z = 0, zMax do
			for x = 0, xMax do
				local newCFrame = minCFrame * CFrame.new(x, y, -z)
				table.insert(CFrames, newCFrame)
			end
		end
	end

	return CFrames
end

return render3dGrid
