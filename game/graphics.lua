local util = require("util")

local consts = require("consts")

local game = {}

function game:clearFramebuffer()
	local framebuffer = self.currentFramebuffer
	for x = 0, self.framebufferWidth - 1 do
		local column = framebuffer[x]
		for y = 0, self.framebufferHeight - 1 do
			local cell = column[y]
			cell.character = " "
			cell.foregroundColour = "white"
			cell.backgroundColour = "black"
		end
	end
end

function game:draw() -- After this function completes, the result is in currentFramebuffer
	self.currentFramebuffer, self.otherFramebuffer = self.otherFramebuffer, self.currentFramebuffer
	local framebuffer = self.currentFramebuffer
	local state = self.state
	self:clearFramebuffer()

	local cameraX, cameraY, cameraSightDistance
	if state.player then
		cameraX, cameraY, cameraSightDistance = state.player.x, state.player.y, state.player.creatureType.sightDistance
	else
		cameraX, cameraY, cameraSightDistance = state.lastPlayerX, state.lastPlayerY, state.lastPlayerSightDistance
	end

	local viewportScreenX, viewportScreenY = 1, 1
	local topLeftX = cameraX - math.floor(self.viewportWidth / 2)
	local topLeftY = cameraY - math.floor(self.viewportHeight / 2)

	local visibilityMap, visibilityMapTopLeftX, visibilityMapTopLeftY, visibilityMapWidth, visibilityMapHeight = self:computeVisibilityMap(cameraX, cameraY, cameraSightDistance)
	assert(visibilityMapTopLeftX == topLeftX)
	assert(visibilityMapTopLeftY == topLeftY)
	assert(visibilityMapWidth == self.viewportWidth)
	assert(visibilityMapHeight == self.viewportHeight)

	local function drawCharacterFramebuffer(framebufferX, framebufferY, character, foregroundColour, backgroundColour)
		if
			0 <= framebufferX and framebufferX < self.framebufferWidth and
			0 <= framebufferY and framebufferY < self.framebufferHeight
		then
			local cell = framebuffer[framebufferX][framebufferY]
			cell.character = character
			cell.foregroundColour = foregroundColour
			cell.backgroundColour = backgroundColour
		end
	end

	-- Draw borders
	local borderDouble = true
	local borderNum = borderDouble and 2 or 1
	local borderForeground = "lightGrey"
	local borderBackground = "darkGrey"
	local rectangles = {
		{x = 0, y = 0, w = self.viewportWidth + 2, h = self.viewportHeight + 2},
		{x = 0, y = self.viewportHeight + 1, w = self.consoleWidth + 2, h = self.consoleHeight + 2},
		{x = self.viewportWidth + 1, y = 0, w = self.framebufferWidth - self.viewportWidth - 1, h = self.framebufferHeight - self.consoleHeight - 1}
	}
	local function isBorder(x, y)
		for _, rectangle in ipairs(rectangles) do
			local dx, dy = x - rectangle.x, y - rectangle.y
			if dx >= 0 and dy >= 0 and dx <= rectangle.w - 1 and dy <= rectangle.h - 1 then
				if not (dx > 0 and dy > 0 and dx < rectangle.w - 1 and dy < rectangle.h - 1) then
					return true
				end
			end
		end
		return false
	end
	for x = 0, self.framebufferWidth - 1 do
		for y = 0, self.framebufferHeight - 1 do
			if not isBorder(x, y) then
				goto continue
			end
			local character = util.getBoxDrawingCharacter(
				isBorder(x + 1, y) and borderNum or 0,
				isBorder(x, y - 1) and borderNum or 0,
				isBorder(x - 1, y) and borderNum or 0,
				isBorder(x, y + 1) and borderNum or 0
			)
			if character then
				drawCharacterFramebuffer(x, y, character, borderForeground, borderBackground)
			end
		    ::continue::
		end
	end

	local function drawCharacterWorldToViewport(worldX, worldY, character, foregroundColour, backgroundColour)
		local viewportX = worldX - topLeftX
		local viewportY = worldY - topLeftY
		if
			0 <= viewportX and viewportX < self.viewportWidth and
			0 <= viewportY and viewportY < self.viewportHeight
		then
			local cell = framebuffer[viewportX + viewportScreenX][viewportY + viewportScreenY]
			cell.character = character
			cell.foregroundColour = foregroundColour
			cell.backgroundColour = backgroundColour
		end
	end
	local function drawCharacterWorldToViewportVisibleOnly(worldX, worldY, character, foregroundColour, backgroundColour)
		local viewportX = worldX - topLeftX
		local viewportY = worldY - topLeftY
		if
			0 <= viewportX and viewportX < self.viewportWidth and
			0 <= viewportY and viewportY < self.viewportHeight
		then
			local visibilityColumn = visibilityMap[viewportX]
			if not (visibilityColumn and visibilityColumn[viewportY]) then
				return
			end
			local cell = framebuffer[viewportX + viewportScreenX][viewportY + viewportScreenY]
			cell.character = character
			cell.foregroundColour = foregroundColour
			cell.backgroundColour = backgroundColour
		end
	end

	for viewportSpaceX = 0, self.viewportWidth - 1 do
		local visibilityColumn = visibilityMap[viewportSpaceX]
		local framebufferX = viewportSpaceX + viewportScreenX
		local column = framebuffer[framebufferX]
		for viewportSpaceY = 0, self.viewportHeight - 1 do
			if not visibilityColumn[viewportSpaceY] then
				goto continue
			end
			local framebufferY = viewportSpaceY + viewportScreenY
			local cell = column[framebufferY]

			local tileX, tileY = viewportSpaceX + topLeftX, viewportSpaceY + topLeftY
			local tile = self:getTile(tileX, tileY)

			if not tile then
				cell.character = " "
				cell.foregroundColour = "white"
				cell.backgroundColour = "black"
				goto continue
			end

			cell.backgroundColour = "black"

			local tileType = state.tileTypes[tile.type]
			cell.foregroundColour = state.materials[tile.material].colour
			if tileType.darkenColour then
				local darker = consts.darkerColours[cell.foregroundColour]
				if darker then
					cell.foregroundColour = darker
				end
			end
			cell.character = self:getTileCharacter(tileX, tileY)

			if not tileType.ignoreSpatter then
				local largestSpatter
				if tile.spatter then
					for _, spatter in ipairs(tile.spatter) do
						if not largestSpatter or spatter.amount >= largestSpatter.amount then
							largestSpatter = spatter
						end
					end
				end
				if largestSpatter and largestSpatter.amount >= consts.spatterThreshold1 then
					local material = state.materials[largestSpatter.materialName]
					cell.foregroundColour = material.colour
					local matterState = material.matterState
					if tileType.solidity ~= "solid" then
						if largestSpatter.amount >= consts.spatterThreshold4 then
							-- cell.character = matterState == "liquid" and "█" or "▓"
							cell.character = matterState == "liquid" and "≈" or "▒"
						elseif largestSpatter.amount >= consts.spatterThreshold3 then
							cell.character = matterState == "liquid" and "≈" or "▒"
						elseif largestSpatter.amount >= consts.spatterThreshold2 then
							cell.character = matterState == "liquid" and "~" or "░"
						end
					end
				end
			end

			::continue::
		end
	end

	for _, entity in ipairs(state.entities) do
		if entity.entityType == "creature" then
			local background = entity.dead and "darkRed" or "black"
			drawCharacterWorldToViewportVisibleOnly(entity.x, entity.y, entity.creatureType.tile, entity.creatureType.colour, background)
		end
	end

	for _, projectile in ipairs(state.projectiles) do
		drawCharacterWorldToViewportVisibleOnly(projectile.currentX, projectile.currentY, projectile.tile, projectile.colour, "black")
	end

	if state.cursor then
		if self.realTime % 0.5 < 0.25 then
			drawCharacterWorldToViewport(state.cursor.x, state.cursor.y, "X", "yellow", "black")
		end
	end

	-- Console
	local rows = {}
	for i = #state.splitAnnouncements, 1, -1 do
		local line = state.splitAnnouncements[i]
		table.insert(rows, 1, {text = line.text, colour = line.announcement.colour})
		if #rows >= self.consoleHeight then
			break
		end
	end
	for rowI, row in ipairs(rows) do
		for textI = 1, #row.text do
			drawCharacterFramebuffer(
				1 + textI - 1,
				2 + self.viewportHeight + rowI - 1,
				row.text:sub(textI, textI),
				row.colour,
				"black"
			)
		end
	end
end

function game:newFramebuffer()
	local framebuffer = {}
	for x = 0, self.framebufferWidth - 1 do
		local column = {}
		framebuffer[x] = column
		for y = 0, self.framebufferHeight - 1 do
			local cell = {
				character = " ",
				foregroundColour = "white",
				backgroundColour = "black"
			}
			column[y] = cell
		end
	end
	return framebuffer
end

local function getWallConnections(neighbours)
	-- Returns right, up, left, down

	if neighbours.right and neighbours.up and neighbours.left and neighbours.down then
		if neighbours.upRight and neighbours.upLeft and neighbours.downLeft and neighbours.downRight then
			return true, true, true, true
		end

		if neighbours.upRight and neighbours.downLeft and neighbours.downRight then
			return false, true, true, false
		end
		if neighbours.upLeft and neighbours.downLeft and neighbours.downRight then
			return true, true, false, false
		end
		if neighbours.upLeft and neighbours.upRight and neighbours.downRight then
			return false, false, true, true
		end
		if neighbours.upLeft and neighbours.upRight and neighbours.downLeft then
			return true, false, false, true
		end
		return true, true, true, true
	end

	if neighbours.up and neighbours.down and neighbours.left then
		if neighbours.upLeft and neighbours.downLeft then
			return false, true, false, true
		end
		return false, true, true, true
	end
	if neighbours.up and neighbours.down and neighbours.right then
		if neighbours.upRight and neighbours.downRight then
			return false, true, false, true
		end
		return true, true, false, true
	end
	if neighbours.up and neighbours.left and neighbours.right then
		if neighbours.upLeft and neighbours.upRight then
			return true, false, true, false
		end
		return true, true, true, false
	end
	if neighbours.down and neighbours.left and neighbours.right then
		if neighbours.downLeft and neighbours.downRight then
			return true, false, true, false
		end
		return true, false, true, true
	end

	return neighbours.right, neighbours.up, neighbours.left, neighbours.down
end

function game:getTileCharacter(x, y)
	local state = self.state
	local tile = self:getTile(x, y)
	local tileType = state.tileTypes[tile.type]
	if tileType.boxDrawingNumber then
		local neighbours = {}
		for ox = -1, 1 do
			for oy = -1, 1 do
				if ox == 0 and oy == 0 then
					goto continue
				end
				local direction = self:getDirection(ox, oy)
				local tileX, tileY = x + ox, y + oy
				local otherTile = self:getTile(tileX, tileY)
				if not otherTile then
					goto continue
				end
				local sameType = otherTile.type == tile.type
				local groupedAutotiling = tile.autotileGroup or otherTile.autotileGroup
				local sameGroup = tile.autotileGroup == otherTile.autotileGroup
				neighbours[direction] = otherTile and sameType and (not groupedAutotiling or sameGroup)
				::continue::
			end
		end

		local right, up, left, down = getWallConnections(neighbours)

		local num = tileType.boxDrawingNumber
		local boxCharacter = util.getBoxDrawingCharacter(
			right and num or 0,
			up and num or 0,
			left and num or 0,
			down and num or 0
		)
		return boxCharacter or tileType.character
	else
		return tileType.character
	end
end

return game
