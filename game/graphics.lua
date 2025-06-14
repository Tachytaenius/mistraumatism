local utf8 = require("utf8")

local util = require("util")

local consts = require("consts")
local commands = require("commands")

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

function game:draw()
	self.currentFramebuffer, self.otherFramebuffer = self.otherFramebuffer, self.currentFramebuffer
	local framebuffer = self.currentFramebuffer
	self:clearFramebuffer()

	if self.mode == "gameplay" then
		self:drawFramebufferGameplay(framebuffer)
	elseif self.mode == "text" then
		self:drawFramebufferText(framebuffer)
	end

	local fontImage = self.fontImage
	local paletteImage = self.paletteImage
	local characterQuad = self.characterQuad
	local characterColoursShader = self.characterColoursShader

	local characterWidth = fontImage:getWidth() / consts.fontWidthCharacters
	local characterHeight = fontImage:getHeight() / consts.fontHeightCharacters
	love.graphics.setShader(characterColoursShader)
	characterColoursShader:send("palette", paletteImage)
	for x = 0, self.framebufferWidth - 1 do
		local column = self.currentFramebuffer[x]
		for y = 0, self.framebufferHeight - 1 do
			local cell = column[y]
			local characterId = consts.cp437Map[cell.character]
			local fontX = characterId % consts.fontWidthCharacters
			local fontY = math.floor(characterId / consts.fontWidthCharacters)
			characterQuad:setViewport(
				fontX * characterWidth, fontY * characterHeight,
				characterWidth, characterHeight,
				fontImage:getDimensions()
			)
			characterColoursShader:send("backgroundColourPosition", consts.colourCoords[cell.backgroundColour])
			characterColoursShader:send("foregroundColourPosition", consts.colourCoords[cell.foregroundColour])
			love.graphics.draw(fontImage, characterQuad, x * characterWidth, y * characterHeight)
		end
	end
	love.graphics.setShader()
end

function game:drawFramebufferGameplay(framebuffer) -- After this function completes, the result is in currentFramebuffer
	local state = self.state

	local cameraX, cameraY, cameraSightDistance
	if state.player then
		cameraX, cameraY, cameraSightDistance = state.player.x, state.player.y, state.player.creatureType.sightDistance
	else
		cameraX, cameraY, cameraSightDistance = state.lastPlayerX, state.lastPlayerY, state.lastPlayerSightDistance
	end

	local viewportScreenX, viewportScreenY = 1, 1
	local topLeftX = cameraX - math.floor(self.viewportWidth / 2)
	local topLeftY = cameraY - math.floor(self.viewportHeight / 2)

	local visibilityMap, visibilityMapTopLeftX, visibilityMapTopLeftY, visibilityMapWidth, visibilityMapHeight, edgeVisibilityMap = self:computeVisibilityMap(cameraX, cameraY, cameraSightDistance, nil, nil, true)
	assert(visibilityMapTopLeftX == topLeftX)
	assert(visibilityMapTopLeftY == topLeftY)
	assert(visibilityMapWidth == self.viewportWidth)
	assert(visibilityMapHeight == self.viewportHeight)

	local function isTileVisible(x, y)
		local viewportX = x - topLeftX
		local viewportY = y - topLeftY
		if
			0 <= viewportX and viewportX < self.viewportWidth and
			0 <= viewportY and viewportY < self.viewportHeight
		then
			local visibilityColumn = visibilityMap[viewportX]
			return visibilityColumn and visibilityColumn[viewportY]
		end
		return false
	end
	local function isEdgeVisible(x, y, type)
		return edgeVisibilityMap[type][x] and edgeVisibilityMap[type][x][y]
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
	
	local function getTileCharacter(x, y)
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
	
			-- Sever any connections that don't have the right visibility
			local rightMask, upMask, leftMask, downMask = false, false, false, false

			local rightEdge = isEdgeVisible(x, y, "vertical")
			if rightEdge then
				rightMask = true
				if not self:tileBlocksLight(x + 1, y) then
					upMask = true
					downMask = true
				end
			end
	
			local upEdge = isEdgeVisible(x, y - 1, "horizontal")
			if upEdge then
				upMask = true
				if not self:tileBlocksLight(x, y - 1) then
					rightMask = true
					leftMask = true
				end
			end
	
			local leftEdge = isEdgeVisible(x - 1, y, "vertical")
			if leftEdge then
				leftMask = true
				if not self:tileBlocksLight(x - 1, y) then
					upMask = true
					downMask = true
				end
			end
	
			local downEdge = isEdgeVisible(x, y, "horizontal")
			if downEdge then
				downMask = true
				if not self:tileBlocksLight(x, y + 1) then
					rightMask = true
					leftMask = true
				end
			end
	
			local right = right and rightMask
			local up = up and upMask
			local left = left and leftMask
			local down = down and downMask
	
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

	local function drawCharacterFramebuffer(framebufferX, framebufferY, character, foregroundColour, backgroundColour)
		assert(consts.cp437Map[character], "Invalid character " .. tostring(character))
		assert(consts.colourCoords[foregroundColour], "Invalid foreground colour " .. tostring(foregroundColour))
		assert(consts.colourCoords[backgroundColour], "Invalid background colour " .. tostring(backgroundColour))
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
	local function drawStringFramebuffer(framebufferX, framebufferY, str, foregroundColour, backgroundColour)
		local x = 0
		local y = 0
		for _, code in utf8.codes(str) do
			local char = utf8.char(code)
			if char == "\n" then
				x = 0
				y = y + 1
				goto continue
			end
			drawCharacterFramebuffer(framebufferX + x, framebufferY + y, char, foregroundColour, backgroundColour)
			x = x + 1
		    ::continue::
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
			drawCharacterFramebuffer(viewportX + viewportScreenX, viewportY + viewportScreenY, character, foregroundColour, backgroundColour)
		end
	end
	local function drawCharacterWorldToViewportVisibleOnly(worldX, worldY, character, foregroundColour, backgroundColour) -- Returns whether the character was drawn
		local viewportX = worldX - topLeftX
		local viewportY = worldY - topLeftY
		if
			0 <= viewportX and viewportX < self.viewportWidth and
			0 <= viewportY and viewportY < self.viewportHeight
		then
			local visibilityColumn = visibilityMap[viewportX]
			if not (visibilityColumn and visibilityColumn[viewportY]) then
				return false
			end
			drawCharacterFramebuffer(viewportX + viewportScreenX, viewportY + viewportScreenY, character, foregroundColour, backgroundColour)
			return true
		end
		return false
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
			cell.character = getTileCharacter(tileX, tileY)

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

	for _, projectile in ipairs(state.projectiles) do
		drawCharacterWorldToViewportVisibleOnly(projectile.currentX, projectile.currentY, projectile.tile, projectile.colour, "black")
	end

	local indicatorTiles = {} -- To stop indicators from clashing
	local drawActionIndicators = self.realTime % 1.5 < 0.5
	local drawCursor = self.realTime % 0.5 < (commands.checkCommand("moveCursor") and 0.4 or 0.25)
	local drawEnemyAim = self.realTime % 0.75 < 0.375
	local drawEntityWarnings = (self.realTime + 0.1875) % 0.75 < 0.375
	local drawActionTime = false
	local function getOffsetSymbol(ox, oy)
		if ox == -1 then
			if oy == -1 then
				return "┌"
			elseif oy == 0 then
				return "<" 
			elseif oy == 1 then
				return "└"
			end
		elseif ox == 0 then
			if oy == -1 then
				return "^"
			elseif oy == 0 then
				return "*"
			elseif oy == 1 then
				return "v"
			end
		elseif ox == 1 then
			if oy == -1 then
				return "┐"
			elseif oy == 0 then
				return ">"
			elseif oy == 1 then
				return "┘"
			end
		end
	end
	local function drawIndicator(destX, destY, character, foreground, background)
		indicatorTiles[destX] = indicatorTiles[destX] or {}
		local current = indicatorTiles[destX][destY]
		local colour = foreground
		if current and (current.character ~= character or current.colour ~= colour or current.clashed) then
			character = "?"
			colour = "darkGrey"
			indicatorTiles[destX][destY] = {
				clashed = true,
				character = character,
				colour = colour
			}
		else
			indicatorTiles[destX][destY] = {
				clashed = false,
				character = character,
				colour = colour
			}
		end
		drawCharacterWorldToViewport(destX, destY, character, colour, "black")
	end
	local function shouldReplaceWithSwitchIndicator(entity)
		local x, y = entity.x, entity.y
		if state.tileEntityLists[x] and state.tileEntityLists[x][y] then
			if #state.tileEntityLists[x][y].all <= 1 then
				return false
			end
		end
		if state.incrementingEntityDisplays then
			return true
		end
		if state.incrementEntityDisplaysTimerLength - state.incrementEntityDisplaysTimer < state.incrementEntityDisplaysSwitchIndicatorTime then
			return true
		end
	end
	local entitiesToDrawVisible = {}
	for _, entity in ipairs(state.entitiesToDraw) do
		local viewportX = entity.x - topLeftX
		local viewportY = entity.y - topLeftY
		if
			0 <= viewportX and viewportX < self.viewportWidth and
			0 <= viewportY and viewportY < self.viewportHeight
		then
			local visibilityColumn = visibilityMap[viewportX]
			if not (visibilityColumn and visibilityColumn[viewportY]) then
				goto continue
			end
			entitiesToDrawVisible[#entitiesToDrawVisible+1] = entity
		end
	    ::continue::
	end
	local drawnEntities = {}
	for _, entity in ipairs(entitiesToDrawVisible) do
		if shouldReplaceWithSwitchIndicator(entity) then
			drawCharacterWorldToViewportVisibleOnly(entity.x, entity.y, "&", "red", "black")
			goto continue
		end

		if entity.entityType == "creature" then
			local background = entity.dead and (entity.creatureType.bloodMaterialName and state.materials[entity.creatureType.bloodMaterialName].colour or "darkRed") or "black"
			drawnEntities[entity] = drawCharacterWorldToViewportVisibleOnly(entity.x, entity.y, entity.creatureType.tile, entity.creatureType.colour, background)
			if drawEntityWarnings and entity ~= state.player and entity.actions[1] and entity.actions[1].type == "shoot" then
				drawIndicator(entity.x, entity.y, "!", "red", "black")
			end
		else
			local background = "black"
			local tile = entity.itemData.itemType.tile
			if entity.doorTile and entity.doorTile.doorData.open then
				tile = entity.itemData.itemType.openTile
			end
			drawnEntities[entity] = drawCharacterWorldToViewportVisibleOnly(entity.x, entity.y, tile, state.materials[entity.itemData.material].colour, background)
		end
	    ::continue::
	end
	for _, entity in ipairs(entitiesToDrawVisible) do
		if entity.entityType ~= "creature" then
			goto continue
		end
		if not (drawActionIndicators and drawnEntities[entity] and entity ~= state.player) then
			goto continue
		end
		local character, colour
		local action = entity.actions[1]
		if not action or action.type ~= "move" and action.type ~= "melee" then
			goto continue
		end
		local ox, oy = self:getDirectionOffset(action.direction)
		local destX, destY = entity.x + ox, entity.y + oy
		colour = action.type == "melee" and "red" or "green"
		if drawActionTime then
			local time = action.timer
			if time > 9 then
				character = "#"
			else
				character = tostring(time):sub(1, 1)
			end
		else
			character = getOffsetSymbol(ox, oy)
		end
		if not character then
			goto continue
		end
		drawIndicator(destX, destY, character, colour, "black")
	    ::continue::
	end
	local cursorEntity = self:getCursorEntity()
	if
		drawEnemyAim and
		cursorEntity and
		cursorEntity.entityType == "creature" and
		cursorEntity.actions[1] and
		cursorEntity.actions[1].type == "shoot"
	then
		local action = cursorEntity.actions[1]
		drawIndicator(action.relativeX + cursorEntity.x, action.relativeY + cursorEntity.y, "X", "red", "black")
	end

	if state.cursor then
		if drawCursor then
			drawCharacterWorldToViewport(state.cursor.x, state.cursor.y, "X", (self:getCursorEntity() and state.cursor.lockedOn) and "cyan" or "yellow", "black")
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

	-- Status panel

	local statusX = self.viewportWidth + 2
	local statusY = 1
	local statusWidth = self.framebufferWidth - self.viewportWidth - 3
	local statusHeight = self.framebufferHeight - self.consoleHeight - 3

	local entityStatusHeight = 6
	local function drawEntityStatus(entity, title, yShift)
		local rectangles = {
			{x = 0, y = yShift, w = statusWidth, h = 6},
			{x = 0, y = yShift, w = 3, h = 3}
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
		local borderNum = 1
		for x = 0, statusWidth - 1 do
			for y = 0, statusHeight - 1 do
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
					drawCharacterFramebuffer(statusX + x, statusY + y, character, "white", "black")
				end
				::continue::
			end
		end
		local relation = state.player and entity and self:getTeamRelation(state.player.team, entity.team)
		local titleColour = relation and (relation == "friendly" and "green" or relation == "neutral" and "yellow" or relation == "enemy" and "red") or "lightGrey"
		if entity and entity.entityType == "item" then
			titleColour = "lightGrey"
		end
		drawStringFramebuffer(statusX + 3, statusY + yShift, title, titleColour, "black")
		if entity and entity.entityType == "creature" then
			drawCharacterFramebuffer(statusX + 1, statusY + 1 + yShift, entity.creatureType.tile, entity.creatureType.colour, "black")
			drawStringFramebuffer(statusX + 3, statusY + 1 + yShift, util.capitalise(entity.creatureType.displayName, false), "lightGrey", "black")
			local healthInfo = entity.health .. "H"
			if entity.dead then
				healthInfo = "Dead"
			end
			if entity.blood then
				healthInfo = healthInfo .. "∙" .. entity.blood .. "B" .. "∙-" .. entity.bleedingAmount
			end
			drawStringFramebuffer(statusX + 3, statusY + 2 + yShift, healthInfo, "lightGrey", "black")
			local actionInfo
			local actionColour = "lightGrey"
			local action = entity.actions[1]
			if not action then
				actionInfo = "No action"
			else
				if action.type == "shoot" or action.type == "melee" then
					actionColour = "red"
				else
					actionColour = "darkCyan"
				end
				actionInfo = util.capitalise(state.actionTypes[action.type].displayName) .. "∙" .. action.timer .. "T"
				if action.type == "move" or action.type == "melee" then
					local symbol = getOffsetSymbol(self:getDirectionOffset(action.direction))
					if symbol then
						actionInfo = actionInfo .. "∙" .. symbol
					end
				end
			end
			drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, actionInfo, actionColour, "black")
			if self:getHeldItem(entity) then
				local itemName = util.capitalise(self:getHeldItem(entity).itemType.displayName, false)
				drawStringFramebuffer(statusX + 1, statusY + 4 + yShift, itemName, "lightGrey", "black")
			end
		elseif entity and entity.entityType == "item" then
			drawCharacterFramebuffer(statusX + 1, statusY + 1 + yShift, entity.itemData.itemType.tile, state.materials[entity.itemData.material].colour, "black")
			drawStringFramebuffer(statusX + 3, statusY + 1 + yShift, util.capitalise(entity.itemData.itemType.displayName, false), "lightGrey", "black")
			drawStringFramebuffer(statusX + 3, statusY + 2 + yShift, util.capitalise(state.materials[entity.itemData.material].displayName, false), "lightGrey", "black")
			local item = entity.itemData
			local itemType = item.itemType
			if itemType.isGun then
				local magazineItem = item.magazineData and item or item.insertedMagazine or nil -- The gun itself, an inserted magazine, or nothing
				local gunStatus =
					(item.chamberedRound and (item.chamberedRound.fired and "Fired" or "Live") or "Empty") ..
					"∙" ..
					(item.shotCooldownTimer and "Cycling" or (item.cocked and "Cocked" or "Uncocked")) ..
					"\n" ..
					-- (item.magazineData and (#item.magazineData > 0 and (#item.magazineData .. " in magazineData") or "magazineData empty") or "No magazineData")
					-- (item.magazineData and (#item.magazineData .. "/" .. itemData.magazineCapacity .. " in magazineData") or "No magazineData") -- Not enough space for two double digit numbers
					(magazineItem and ("Magazine: " .. #magazineItem.magazineData .. "/" .. magazineItem.itemType.magazineCapacity) or "No magazine")
				drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, gunStatus, "lightGrey", "black")
			elseif itemType.magazine then -- Would have gone into the block above if it was a gun with its own magazine data
				local magazineStatus = "Magazine: " .. #item.magazineData .. "/" .. item.itemType.magazineCapacity
				drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, magazineStatus, "lightGrey", "black") 
			elseif itemType.isAmmo then
				local ammoStatus = item.fired and "Fired" or "Live"
				drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, ammoStatus, "lightGrey", "black")
			end
		end
	end

	local inventoryHeight = 7
	local function drawInventory()
		local rectangles = {}
		for x = 0, 2 do
			for y = 0, 2 do
				rectangles[#rectangles+1] = {x = x * 4 + 2, y = y * 2 + 2 * (entityStatusHeight + 1), w = 5, h = 3}
			end
		end
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
		local borderNum = 1
		for x = 0, statusWidth - 1 do
			for y = 0, statusHeight - 1 do
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
					drawCharacterFramebuffer(statusX + x, statusY + y, character, "white", "black")
				end
				::continue::
			end
		end
		drawStringFramebuffer(statusX + 4, 2 * (entityStatusHeight + 1) + 1, "INVENTORY", "lightGrey", "black")
		if state.player and state.player.inventory then
			for i, slot in ipairs(state.player.inventory) do
				local x = statusX + (i - 1) % 3 * 4 + 4
				local y = 2 * (entityStatusHeight + 1) + 2 + math.floor((i - 1) / 3) * 2
				if i == state.player.inventory.selectedSlot then -- and self.realTime % 0.5 < 0.25 then
					drawCharacterFramebuffer(x - 1, y, "►", "lightGrey", "black")
				end
				if slot.item then
					drawCharacterFramebuffer(x, y, slot.item.itemType.tile, state.materials[slot.item.material].colour, "black")
				end
			end
		end
	end

	drawEntityStatus(state.player and not state.player.dead and state.player or nil, "YOU", 0)
	local entity = self:getCursorEntity()
	drawEntityStatus(state.player and self:getHeldItem(state.player) and {entityType = "item", itemData = self:getHeldItem(state.player)} or nil, "POSSESSION", inventoryHeight) -- HACK
	drawInventory()
	drawEntityStatus(entity, "TARGET", inventoryHeight + 1 + 2 * (entityStatusHeight + 1))

	local yShift = inventoryHeight + 1 + 3 * (entityStatusHeight + 1)
	local rectangles = {
		{x = 0, y = yShift, w = statusWidth, h = 6},
		{x = 0, y = yShift, w = 3, h = 3}
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
	local borderNum = 1
	for x = 0, statusWidth - 1 do
		for y = 0, statusHeight - 1 do
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
				drawCharacterFramebuffer(statusX + x, statusY + y, character, "white", "black")
			end
			::continue::
		end
	end
	drawStringFramebuffer(statusX + 3, statusY + yShift, "TILE", "lightGrey", "black")
	if state.cursor and state.player and self:entityCanSeeTile(state.player, state.cursor.x, state.cursor.y) then
		local tile = state.cursor and self:getTile(state.cursor.x, state.cursor.y)
		local material = state.materials[tile.material]
		if tile.type then
			drawStringFramebuffer(statusX + 3, statusY + yShift + 1, util.capitalise(state.tileTypes[tile.type].displayName, false), "lightGrey", "black")
		end
		if material then
			drawStringFramebuffer(statusX + 3, statusY + yShift + 2, util.capitalise(material.displayName, false), "lightGrey", "black")
		end
		if tile.type and material then
			drawCharacterFramebuffer(statusX + 1, yShift + statusY + 1, getTileCharacter(tile.x, tile.y), material.colour, "black")
		end
		local largestSpatter
		if tile.spatter then
			for _, spatter in ipairs(tile.spatter) do
				if not largestSpatter or spatter.amount >= largestSpatter.amount then
					largestSpatter = spatter
				end
			end
		end
		local entityList = self:getCursorEntitySelectionList()
		if entityList and #entityList > 0 then
			local selectedEntityIndex
			local selectedEntity = self:getCursorEntity()
			if selectedEntity then
				local function drawEntitySymbol(entity, x, y)
					local character, colour
					if entity.entityType == "creature" then
						character = entity.creatureType.tile
						colour = entity.creatureType.colour
					elseif entity.entityType == "item" then
						character = entity.itemData.itemType.tile
						colour = state.materials[entity.itemData.material].colour
					end
					drawCharacterFramebuffer(x, y, character, colour, "black")
				end

				selectedEntityIndex = self:getSelectedEntityListIndex()
				assert(selectedEntityIndex, "Selected cursor entity is not in the list of currently selectable entities")

				drawCharacterFramebuffer(statusX + 5, statusY + yShift + 3, "►", state.cursor.lockedOn and "cyan" or "yellow", "black")
				local zeroX = statusX + 6
				for i, entity in ipairs(entityList) do
					local relative =  i - selectedEntityIndex
					local separation = relative < 0 and -2 or relative > 0 and 1 or 0
					local drawX = zeroX + relative + separation
					if drawX > statusX + 1 and drawX < statusX + 10 then
						drawEntitySymbol(entity, drawX, statusY + yShift + 3)
					end
				end
			else

			end
			drawCharacterFramebuffer(statusX + 1, statusY + yShift + 3, "[", "darkGrey", "black")
			drawCharacterFramebuffer(statusX + 10, statusY + yShift + 3, "]", "darkGrey", "black")
			drawStringFramebuffer(statusX + 12, statusY + yShift + 3, (selectedEntityIndex and (
				string.format("%2s", selectedEntityIndex)
			) or "--"), "lightGrey", "black")
			drawStringFramebuffer(statusX + 14, statusY + yShift + 3, "/" .. #entityList, "lightGrey", "black")
		else
			drawStringFramebuffer(statusX + 1, statusY + yShift + 3, "No targets", "lightGrey", "black")
		end
		if largestSpatter then
			local material = state.materials[largestSpatter.materialName]
			local str = material.displayName .. "∙" .. largestSpatter.amount
			drawStringFramebuffer(statusX + 1, statusY + yShift + 4, str, "lightGrey", "black")
			if #tile.spatter > 1 then
				drawCharacterFramebuffer(statusX + statusWidth - 2, statusY + yShift + 4, "+", "lightGrey", "black")
			end
		else
			drawStringFramebuffer(statusX + 1, statusY + yShift + 4, "No spatter", "lightGrey", "black")
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

function game:drawFramebufferText(framebuffer)
	-- Copied
	local function drawCharacterFramebuffer(framebufferX, framebufferY, character, foregroundColour, backgroundColour)
		assert(consts.cp437Map[character], "Invalid character " .. tostring(character))
		assert(consts.colourCoords[foregroundColour], "Invalid foreground colour " .. tostring(foregroundColour))
		assert(consts.colourCoords[backgroundColour], "Invalid background colour " .. tostring(backgroundColour))
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
	local function drawStringFramebufferColourMapFunction(framebufferX, framebufferY, str)
		local x = 0
		local y = 0
		for _, code in utf8.codes(str) do
			local char = utf8.char(code)
			if char == "\n" then
				x = 0
				y = y + 1
				goto continue
			end
			drawCharacterFramebuffer(framebufferX + x, framebufferY + y, char, self.textInfo.getColour(framebufferX + x, framebufferY + y))
			x = x + 1
		    ::continue::
		end
	end

	drawStringFramebufferColourMapFunction(0, 0, self.textInfo.text)
end

return game
