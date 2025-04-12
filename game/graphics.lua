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

	local viewportScreenX, viewportScreenY = 1, 1
	local topLeftX = math.floor(state.player.x - self.viewportWidth / 2)
	local topLeftY = math.floor(state.player.y - self.viewportHeight / 2)
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

	local visibilityMap, visibilityMapTopLeftX, visibilityMapTopLeftY, visibilityMapWidth, visibilityMapHeight = self:computeVisibilityMap(state.player.x, state.player.y, 24) -- For the next draw(s)
	assert(visibilityMapTopLeftX == topLeftX)
	assert(visibilityMapTopLeftY == topLeftY)
	assert(visibilityMapWidth == self.viewportWidth)
	assert(visibilityMapHeight == self.viewportHeight)

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
			cell.foregroundColour = "lightGrey"
			if tileType.darkenColour then
				local darker = consts.darkerColours[cell.foregroundColour]
				if darker then
					cell.foregroundColour = darker
				end
			end
			if tileType.boxDrawingNumber then
				local right = self:getTile(tileX + 1, tileY)
				local up    = self:getTile(tileX, tileY - 1)
				local left  = self:getTile(tileX - 1, tileY)
				local down  = self:getTile(tileX, tileY + 1)
				local num = tileType.boxDrawingNumber
				local boxCharacter = util.getBoxDrawingCharacter(
					right and right.type == tile.type and num or 0,
					up    and up.type == tile.type    and num or 0,
					left  and left.type == tile.type  and num or 0,
					down  and down.type == tile.type  and num or 0
				)
				cell.character = boxCharacter or tileType.character
			else
				cell.character = tileType.character
			end

			if not tileType.ignoreSpatter then
				local largestSpatter
				if tile.spatter then
					for _, spatter in ipairs(tile.spatter) do
						if not largestSpatter or spatter.amount >= largestSpatter.amount then
							largestSpatter = spatter
						end
					end
				end
				if largestSpatter and largestSpatter.amount >= 1 then
					local material = state.materials[largestSpatter.materialName]
					cell.foregroundColour = material.colour
					local matterState = material.matterState
					if tileType.solidity ~= "solid" then
						if largestSpatter.amount >= 4 then
							-- cell.character = matterState == "liquid" and "█" or "▓"
							cell.character = matterState == "liquid" and "≈" or "▒"
						elseif largestSpatter.amount >= 3 then
							cell.character = matterState == "liquid" and "≈" or "▒"
						elseif largestSpatter.amount >= 2 then
							cell.character = matterState == "liquid" and "~" or "░"
						end
					end
				end
			end

			::continue::
		end
	end

	-- Draw viewport box
	local borderDouble = true
	local borderNum = borderDouble and 2 or 1
	local borderForeground = "lightGrey"
	local borderBackground = "darkGrey"
	for ySide = 0, 1 do
		local framebufferY = viewportScreenY + self.viewportHeight * ySide - (1 - ySide)
		for framebufferX = viewportScreenX, viewportScreenX + self.viewportWidth - 1 do
			local character = util.getBoxDrawingCharacter(borderNum, 0, borderNum, 0)
			drawCharacterFramebuffer(framebufferX, framebufferY, character, borderForeground, borderBackground)
		end
	end
	for xSide = 0, 1 do
		local framebufferX = viewportScreenX + self.viewportWidth * xSide - (1 - xSide)
		for framebufferY = viewportScreenY, viewportScreenY + self.viewportHeight - 1 do
			local character = util.getBoxDrawingCharacter(0, borderNum, 0, borderNum)
			drawCharacterFramebuffer(framebufferX, framebufferY, character, borderForeground, borderBackground)
		end
	end
	for xSide = 0, 1 do
		local framebufferX = viewportScreenX + self.viewportWidth * xSide - (1 - xSide)
		for ySide = 0, 1 do
			local framebufferY = viewportScreenY + self.viewportHeight * ySide - (1 - ySide)
			local character = util.getBoxDrawingCharacter(
				borderNum * (1 - xSide),
				borderNum * ySide,
				borderNum * xSide,
				borderNum * (1 - ySide)
			)
			drawCharacterFramebuffer(framebufferX, framebufferY, character, borderForeground, borderBackground)
		end
	end

	for _, entity in ipairs(state.entities) do
		drawCharacterWorldToViewport(entity.x, entity.y, entity.type.tile, entity.type.colour, "black")
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

return game
