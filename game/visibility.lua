local game = {}

-- Not my algorithm, it's:
-- http://www.adammil.net/blog/view.php?id=125

function game:computeVisibilityMap(startX, startY, rangeLimit)
	local visibilityMapWidth, visibilityMapHeight = self.viewportWidth, self.viewportHeight
	local visibilityMapTopLeftX = math.floor(startX - visibilityMapWidth / 2)
	local visibilityMapTopLeftY = math.floor(startY - visibilityMapHeight / 2)
	local visibilityMap = {}
	for x = 0, visibilityMapWidth - 1 do
		local column = {}
		visibilityMap[x] = column
		for y = 0, visibilityMapHeight - 1 do
			column[y] = false
		end
	end

	local function blocksLightBasic(x, y)
		local tile = self:getTile(x, y)
		if not tile then
			return true
		end
		return tile.type == "wall"
	end

	local function getDistance(x, y)
		return math.floor(math.sqrt(x ^ 2 + y ^ 2))
	end

	local function setVisibleBasic(x, y)
		local mapX, mapY = x - visibilityMapTopLeftX, y - visibilityMapTopLeftY
		if
			0 <= mapX and mapX < visibilityMapWidth and
			0 <= mapY and mapY < visibilityMapHeight
		then
			visibilityMap[mapX][mapY] = true
		end
	end

	local function blocksLight(x, y, octant, startX, startY)
		local nx = startX
		local ny = startY
		if octant == 0 then
			nx = nx + x
			ny = ny - y
		elseif octant == 1 then
			nx = nx + y
			ny = ny - x
		elseif octant == 2 then
			nx = nx - y
			ny = ny - x
		elseif octant == 3 then
			nx = nx - x
			ny = ny - y
		elseif octant == 4 then
			nx = nx - x
			ny = ny + y
		elseif octant == 5 then
			nx = nx - y
			ny = ny + x
		elseif octant == 6 then
			nx = nx + y
			ny = ny + x
		elseif octant == 7 then
			nx = nx + x
			ny = ny + y
		end
		return blocksLightBasic(nx, ny)
	end

	local function setVisible(x, y, octant, startX, startY)
		local nx = startX
		local ny = startY
		if octant == 0 then
			nx = nx + x
			ny = ny - y
		elseif octant == 1 then
			nx = nx + y
			ny = ny - x
		elseif octant == 2 then
			nx = nx - y
			ny = ny - x
		elseif octant == 3 then
			nx = nx - x
			ny = ny - y
		elseif octant == 4 then
			nx = nx - x
			ny = ny + y
		elseif octant == 5 then
			nx = nx - y
			ny = ny + x
		elseif octant == 6 then
			nx = nx + y
			ny = ny + x
		elseif octant == 7 then
			nx = nx + x
			ny = ny + y
		end
		return setVisibleBasic(nx, ny)
	end

	local function slopeGreater(x1, y1, x2, y2)
		return y1 * x2 > x1 * y2
	end

	local function slopeGreaterOrEqual(x1, y1, x2, y2)
		return y1 * x2 >= x1 * y2
	end

	local function slopeLess(x1, y1, x2, y2)
		return y1 * x2 < x1 * y2
	end

	local function slopeLessOrEqual(x1, y1, x2, y2)
		return y1 * x2 <= x1 * y2
	end

	local function compute(octant, startX, startY, rangeLimit, x, slopeTopX, slopeTopY, slopeBottomX, slopeBottomY)
		while x <= rangeLimit do
			local topY
			if slopeTopX == 1 then
				topY = x
			else
				topY = math.floor(((x * 2 - 1) * slopeTopY + slopeTopX) / (slopeTopX * 2))
				if blocksLight(x, topY, octant, startX, startY) then
					if slopeGreaterOrEqual(slopeTopX, slopeTopY, x * 2, topY * 2 + 1) and not blocksLight(x, topY + 1, octant, startX, startY) then
						topY = topY + 1
					end
				else
					local ax = x * 2
					if blocksLight(x + 1, topY + 1, octant, startX, startY) then
						ax = ax + 1
					end
					if slopeGreater(slopeTopX, slopeTopY, ax, topY * 2 + 1) then
						topY = topY + 1
					end
				end
			end

			local bottomY
			if slopeBottomY == 0 then
				bottomY = 0
			else
				bottomY = math.floor(((x * 2 - 1) * slopeBottomY + slopeBottomX) / (slopeBottomX * 2))
				if
					slopeGreaterOrEqual(slopeBottomX, slopeBottomY, x * 2, bottomY * 2 + 1) and
					blocksLight(x, bottomY, octant, startX, startY) and
					not blocksLight(x, bottomY + 1, octant, startX, startY)
				then
					bottomY = bottomY + 1
				end
			end

			local wasOpaque = -1
			for y = topY, bottomY, -1 do
				if rangeLimit < 0 or getDistance(x, y) <= rangeLimit then
					local isOpaque = blocksLight(x, y, octant, startX, startY)
					-- local isVisible = isOpaque or ((y ~= topY or slopeGreater(slopeTopX, slopeTopY, x * 4 + 1, y * 4 - 1)) and (y ~= bottomY or slopeLess(slopeBottomX, slopeBottomY, x * 4 - 1, y * 4 + 1)))
					local isVisible = (y ~= topY or slopeGreaterOrEqual(slopeTopX, slopeTopY, x, y)) and (y ~= bottomY or slopeLessOrEqual(slopeBottomX, slopeBottomY, x, y))
					if isVisible then
						setVisible(x, y, octant, startX, startY)
					end

					if x ~= rangeLimit then
						if isOpaque then
							if wasOpaque == 0 then
								local nx = x * 2
								local ny = y * 2 + 1
								-- if blocksLight(x, y + 1, octant, startX, startY) then
								-- 	nx = nx - 1
								-- end
								if slopeGreater(slopeTopX, slopeTopY, nx, ny) then
									if y == bottomY then
										slopeBottomY = ny
										slopeBottomX = nx
										break
									else
										compute(octant, startX, startY, rangeLimit, x + 1, slopeTopX, slopeTopY, nx, ny)
									end
								else
									if y == bottomY then
										return
									end
								end
							end
							wasOpaque = 1
						else
							if wasOpaque > 0 then
								local nx = x * 2
								local ny = y * 2 + 1
								-- if blocksLight(x + 1, y + 1, octant, startX, startY) then
								-- 	nx = nx + 1
								-- end
								if slopeGreaterOrEqual(slopeBottomX, slopeBottomY, nx, ny) then
									return
								end
								slopeTopY, slopeTopX = ny, nx
							end
							wasOpaque = 0
						end
					end
				end
			end

			if wasOpaque ~= 0 then
				break
			end
			x = x + 1
		end
	end

	setVisibleBasic(startX, startY)
	for octant = 0, 7 do
		compute(octant, startX, startY, rangeLimit, 1, 1, 1, 1, 0)
	end

	-- Circle of vision
	-- for x = startX - rangeLimit, startX + rangeLimit do
	-- 	for y = startY - rangeLimit, startY + rangeLimit do
	-- 		if getDistance(x - startX, y - startY) <= rangeLimit then
	-- 			setVisibleBasic(x, y)
	-- 		end
	-- 	end
	-- end

	return visibilityMap, visibilityMapTopLeftX, visibilityMapTopLeftY, visibilityMapWidth, visibilityMapHeight
end

return game
