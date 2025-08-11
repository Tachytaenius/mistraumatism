local game = {}

-- Not my algorithm, it's:
-- http://www.adammil.net/blog/view.php?id=125

function game:tileBlocksLight(x, y, allowSlipPast)
	local tile = self:getTile(x, y)
	if not tile then
		return true
	end
	if tile.doorData and not tile.doorData.open and not tile.doorData.entity.itemData.itemType.doorWindow then
		return true
	end
	if allowSlipPast and self.state.tileTypes[tile.type].lightSlipPast then
		return false
	end
	return self.state.tileTypes[tile.type].blocksLight
end

local function setVisibleBasic(x, y, visibilityMapInfo)
	local mapX, mapY = x - visibilityMapInfo.visibilityMapTopLeftX, y - visibilityMapInfo.visibilityMapTopLeftY
	if
		0 <= mapX and mapX < visibilityMapInfo.visibilityMapWidth and
		0 <= mapY and mapY < visibilityMapInfo.visibilityMapHeight
	then
		visibilityMapInfo.visibilityMap[mapX][mapY] = true
	end
end

function game:tileBlocksPathOctant(x, y, octant, startX, startY, blockFunction)
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
	return blockFunction and blockFunction(self, nx, ny) or self:tileBlocksLight(nx, ny)
end

local function setVisible(x, y, octant, startX, startY, visibilityMapInfo)
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
	return setVisibleBasic(nx, ny, visibilityMapInfo)
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

function game:computeVisibilityMapOctant(octant, startX, startY, rangeLimit, x, slopeTopX, slopeTopY, slopeBottomX, slopeBottomY, disableDistanceCheck, visibilityMapInfo)
	local function handleCollision()
		if visibilityMapInfo.singleLine then
			visibilityMapInfo.collidedX = x
		end
	end

	local stepped = false
	while x <= rangeLimit do
		local topY
		if slopeTopX == 1 then
			topY = x
		else
			topY = math.floor(((x * 2 - 1) * slopeTopY + slopeTopX) / (slopeTopX * 2))
			if self:tileBlocksPathOctant(x, topY, octant, startX, startY, visibilityMapInfo.blockFunction) then
				if slopeGreaterOrEqual(slopeTopX, slopeTopY, x * 2, topY * 2 + 1) and not self:tileBlocksPathOctant(x, topY + 1, octant, startX, startY, visibilityMapInfo.blockFunction) then
					topY = topY + 1
				end
			else
				local ax = x * 2
				if self:tileBlocksPathOctant(x + 1, topY + 1, octant, startX, startY, visibilityMapInfo.blockFunction) then
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
				self:tileBlocksPathOctant(x, bottomY, octant, startX, startY, visibilityMapInfo.blockFunction) and
				not self:tileBlocksPathOctant(x, bottomY + 1, octant, startX, startY, visibilityMapInfo.blockFunction)
			then
				bottomY = bottomY + 1
			end
		end

		local wasOpaque = -1
		for y = topY, bottomY, -1 do
			local globalX, globalY
			if visibilityMapInfo.edgeMap or not visibilityMapInfo.wholeMap then
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
				globalX, globalY = nx, ny
			end

			local isOpaque = self:tileBlocksPathOctant(x, y, octant, startX, startY, visibilityMapInfo.blockFunction)
			local isVisible = (y ~= topY or slopeGreaterOrEqual(slopeTopX, slopeTopY, x, y)) and (y ~= bottomY or slopeLessOrEqual(slopeBottomX, slopeBottomY, x, y))
			local openVisible = isVisible and not isOpaque

			if rangeLimit < 0 or disableDistanceCheck or (not disableDistanceCheck and self:length(x, y) <= (visibilityMapInfo.distanceCheckRangeLimit or rangeLimit)) then
				if isVisible then
					if visibilityMapInfo.wholeMap then
						setVisible(x, y, octant, startX, startY, visibilityMapInfo)
					else
						if globalX == visibilityMapInfo.globalEndX and globalY == visibilityMapInfo.globalEndY then
							visibilityMapInfo.endTileVisible = true
						end
					end
				end

				if not visibilityMapInfo.wholeMap then
					local tile = self:getTile(globalX, globalY)
					if tile and not visibilityMapInfo.hitTiles[tile] then
						local hitTileInfo = {
							localX = x, localY = y,
							globalX = globalX, globalY = globalY,
							fullHit = isVisible,
							tile = tile
						}
						visibilityMapInfo.hitTiles[tile] = hitTileInfo
						visibilityMapInfo.hitTiles[#visibilityMapInfo.hitTiles+1] = hitTileInfo
					end
				end

				if x ~= rangeLimit then
					if isOpaque then
						if wasOpaque == 0 then
							local nx = x * 2
							local ny = y * 2 + 1
							-- if self:tileBlocksPathOctant(x, y + 1, octant, startX, startY, visibilityMapInfo.blockFunction) then
							-- 	nx = nx - 1
							-- end
							if slopeGreater(slopeTopX, slopeTopY, nx, ny) then
								if y == bottomY then
									slopeBottomY = ny
									slopeBottomX = nx
									break
								else
									if visibilityMapInfo.sectorsNextStep then
										local xTable = visibilityMapInfo.sectorsNextStep[x + 1] or {}
										visibilityMapInfo.sectorsNextStep[x + 1] = xTable
										xTable[#xTable+1] = {
											slopeTopX = slopeTopX,
											slopeTopY = slopeTopY,
											slopeBottomX = nx,
											slopeBottomY = ny,
											octant = octant
										}
									end
									self:computeVisibilityMapOctant(octant, startX, startY, rangeLimit, x + 1, slopeTopX, slopeTopY, nx, ny, disableDistanceCheck, visibilityMapInfo)
								end
							else
								if y == bottomY then
									handleCollision()
									return
								end
							end
						end
						wasOpaque = 1
					else
						if wasOpaque > 0 then
							local nx = x * 2
							local ny = y * 2 + 1
							-- if self:tileBlocksPathOctant(x + 1, y + 1, octant, startX, startY, visibilityMapInfo.blockFunction) then
							-- 	nx = nx + 1
							-- end
							if slopeGreaterOrEqual(slopeBottomX, slopeBottomY, nx, ny) then
								handleCollision()
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
			handleCollision()
			break
		end
		if visibilityMapInfo.sectorsNextStep then
			local xTable = visibilityMapInfo.sectorsNextStep[x + 1] or {}
			visibilityMapInfo.sectorsNextStep[x + 1] = xTable
			xTable[#xTable+1] = {
				slopeTopX = slopeTopX,
				slopeTopY = slopeTopY,
				slopeBottomX = slopeBottomX,
				slopeBottomY = slopeBottomY,
				octant = octant
			}
		end
		x = x + 1
	end
end

function game:computeVisibilityMap(startX, startY, rangeLimit, disableDistanceCheck, allVisible, edges)
	allVisible = allVisible or false -- no nil
	local visibilityMapWidth, visibilityMapHeight = self.viewportWidth, self.viewportHeight
	local visibilityMapTopLeftX = startX - math.floor(visibilityMapWidth / 2)
	local visibilityMapTopLeftY = startY - math.floor(visibilityMapHeight / 2)
	local visibilityMap = {}
	for x = 0, visibilityMapWidth - 1 do
		local column = {}
		visibilityMap[x] = column
		for y = 0, visibilityMapHeight - 1 do
			column[y] = allVisible
		end
	end

	local visibilityMapInfo = {
		wholeMap = true,
		visibilityMapWidth = visibilityMapWidth,
		visibilityMapHeight = visibilityMapHeight,
		visibilityMapTopLeftX = visibilityMapTopLeftX,
		visibilityMapTopLeftY = visibilityMapTopLeftY,
		visibilityMap = visibilityMap,
		edgeMap = edges and {vertical = {}, horizontal = {}}
	}
	if not allVisible then
		setVisibleBasic(startX, startY, visibilityMapInfo)
		local edges = visibilityMapInfo.edgeMap
		edges.vertical[startX - 1] = edges.vertical[startX - 1] or {}
		edges.vertical[startX - 1][startY] = true
		edges.vertical[startX] = edges.vertical[startX] or {}
		edges.vertical[startX][startY] = true
		edges.horizontal[startX] = edges.horizontal[startX] or {}
		edges.horizontal[startX][startY - 1] = true
		edges.horizontal[startX] = edges.horizontal[startX] or {}
		edges.horizontal[startX][startY] = true
		for octant = 0, 7 do
			self:computeVisibilityMapOctant(octant, startX, startY, rangeLimit, 1, 1, 1, 1, 0, disableDistanceCheck, visibilityMapInfo)
		end
	else
		
	end

	if edges then
		local function setEdge(edgeTileX, edgeTileY, edgeType)
			local typeTable = visibilityMapInfo.edgeMap[edgeType]
			if not typeTable[edgeTileX] then
				typeTable[edgeTileX] = {}
			end
			typeTable[edgeTileX][edgeTileY] = true
		end
		local edgeMap = visibilityMapInfo.edgeMap
		-- We start at -1 on x and y to get the top and left edges of the screen
		for x = -1, visibilityMapWidth - 1 do
			local worldX = visibilityMapTopLeftX + x
			for y = -1, visibilityMapHeight - 1 do
				local worldY = visibilityMapTopLeftY + y

				if (visibilityMap[x] and visibilityMap[x][y]) then
					if not self:tileBlocksLight(worldX, worldY) then
						for X = worldX - 1, worldX do
							for Y = worldY - 1, worldY + 1 do
							-- for Y = worldY, worldY do
								setEdge(X, Y, "vertical")
							end
						end
						for X = worldX - 1, worldX + 1 do
						-- for X = worldX, worldX do
							for Y = worldY - 1, worldY do
								setEdge(X, Y, "horizontal")
							end
						end
					else
						if startX <= worldX then
							setEdge(worldX - 1, worldY, "vertical")
						end
						if startX >= worldX then
							setEdge(worldX, worldY, "vertical")
						end

						if startY <= worldY then
							setEdge(worldX, worldY - 1, "horizontal")
						end
						if startY >= worldY then
							setEdge(worldX, worldY, "horizontal")
						end
					end
				end
			end
		end
	end

	return visibilityMap, visibilityMapTopLeftX, visibilityMapTopLeftY, visibilityMapWidth, visibilityMapHeight, edges and visibilityMapInfo.edgeMap or nil
end

-- Return values:
-- - true, {sameTile = true}
-- - true, octantInfoTable
-- - false, {octants = listOfOctantInfoTables}
-- Octant info table data:
-- - octant
-- - hitTiles
-- - collidedX
function game:hitscan(startX, startY, endX, endY, blockFunction)
	if startX == endX and startY == endY then
		return true, {sameTile = true}
	end

	local deltaX, deltaY = endX - startX, endY - startY
	local magX, magY = math.abs(deltaX), math.abs(deltaY)
	local rangeLimit = math.max(math.abs(deltaX), math.abs(deltaY))

	-- local octant
	-- local localX, localY
	-- if deltaX > 0 and deltaY < 0 then
	-- 	if magX > magY then
	-- 		octant = 0
	-- 		localX, localY = magX, magY
	-- 	elseif magX < magY then
	-- 		octant = 1
	-- 		localX, localY = magY, magX
	-- 	end
	-- elseif deltaX < 0 and deltaY < 0 then
	-- 	if magX > magY then
	-- 		octant = 3
	-- 		localX, localY = magX, magY
	-- 	elseif magX < magY then
	-- 		octant = 2
	-- 		localX, localY = magY, magX
	-- 	end
	-- elseif deltaX < 0 and deltaY > 0 then
	-- 	if magX > magY then
	-- 		octant = 4
	-- 		localX, localY = magX, magY
	-- 	elseif magX < magY then
	-- 		octant = 5
	-- 		localX, localY = magY, magX
	-- 	end
	-- elseif deltaX > 0 and deltaY > 0 then
	-- 	if magX > magY then
	-- 		octant = 7
	-- 		localX, localY = magX, magY
	-- 	elseif magX < magY then
	-- 		octant = 6
	-- 		localX, localY = magY, magX
	-- 	end
	-- end

	local octants = {}
	for octant = 0, 7 do -- Should only ever actually call computeVisibilityMapOctant with at most two octants
		-- Check if target tile is in the quadrant
		local quadrant = math.floor(octant / 2)
		local xFlip = (quadrant == 1 or quadrant == 2) and -1 or 1
		local yFlip = (quadrant == 0 or quadrant == 1) and -1 or 1
		if not (xFlip * deltaX >= 0 and yFlip * deltaY >= 0) then
			goto continue
		end
		-- Check if the target tile is in the octant
		if (octant + quadrant) % 2 == 0 then
			if magX < magY then
				goto continue
			end
		else
			if magY < magX then
				goto continue
			end
		end

		-- Get position of tile in octant's own space
		local localX, localY
		if (octant + quadrant) % 2 == 0 then
			localX, localY = magX, magY
		else
			localX, localY = magY, magX
		end

		-- Perform check

		local visibilityMapInfo = {
			singleLine = true,
			wholeMap = false,
			globalEndX = endX,
			globalEndY = endY,
			hitTiles = {}, -- Contains info on whether it was a full hit (corresponding to setVisible or just the code looking at that tile)
			blockFunction = blockFunction, -- If present
			endTileVisible = false
		}

		self:computeVisibilityMapOctant(octant, startX, startY, rangeLimit, 1, localX * 4 - 1, localY * 4 + 1, localX * 4 + 1, localY * 4 - 1, true, visibilityMapInfo)

		local info = {octant = octant, hitTiles = visibilityMapInfo.hitTiles, collidedX = visibilityMapInfo.collidedX}
		if visibilityMapInfo.endTileVisible then
			return true, info
		end
		octants[#octants+1] = info
	    ::continue::
	end

	return false, {octants = octants} -- #octants should be 2
end

return game
