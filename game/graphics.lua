local utf8 = require("utf8")

local util = require("util")

local settings = require("settings")
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
	if self.noDraw then
		return
	end

	self.currentFramebuffer, self.otherFramebuffer = self.otherFramebuffer, self.currentFramebuffer
	local framebuffer = self.currentFramebuffer
	self:clearFramebuffer()

	if self.mode == "gameplay" then
		self:drawFramebufferGameplay(framebuffer)
	elseif self.mode == "text" then
		self:drawFramebufferText(framebuffer)
	elseif self.mode == "title" then
		self:drawFramebufferTitle(framebuffer)
	end

	local fontImage = self.fontImage
	local paletteImage = self.paletteImage
	local characterQuad = self.characterQuad
	local characterColoursShader = self.characterColoursShader

	local characterWidth = fontImage:getWidth() / consts.fontWidthCharacters
	local characterHeight = fontImage:getHeight() / consts.fontHeightCharacters
	love.graphics.setShader(characterColoursShader)
	characterColoursShader:send("palette", paletteImage)
	local width, height = self:getCanvasSize()
	local xOffset = (love.graphics.getWidth() - width * settings.graphics.canvasScale) / 2
	local yOffset = (love.graphics.getHeight() - height * settings.graphics.canvasScale) / 2
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
			characterColoursShader:send("backgroundColourCoords", consts.colourCoordsTexel[cell.backgroundColour])
			characterColoursShader:send("foregroundColourCoords", consts.colourCoordsTexel[cell.foregroundColour])
			love.graphics.draw(
				fontImage, characterQuad,
				xOffset + x * characterWidth * settings.graphics.canvasScale,
				yOffset + y * characterHeight * settings.graphics.canvasScale,
				0,
				settings.graphics.canvasScale, settings.graphics.canvasScale
			)
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
	if state.changeToLevelTimer then
		local proportion = math.max(0, state.changeToLevelTimer / consts.changeToLevelTimerLength) ^ 2
		cameraSightDistance = math.floor(proportion * cameraSightDistance)
	elseif state.startLevelTimer then
		local proportion = math.max(0, 1 - state.startLevelTimer / consts.startLevelTimerLength) ^ 0.8
		cameraSightDistance = math.floor(proportion * cameraSightDistance)
	end

	local viewportScreenX, viewportScreenY = 1, 1
	local topLeftX = cameraX - math.floor(self.viewportWidth / 2)
	local topLeftY = cameraY - math.floor(self.viewportHeight / 2)

	local visibilityMap, visibilityMapTopLeftX, visibilityMapTopLeftY, visibilityMapWidth, visibilityMapHeight, edgeVisibilityMap = self:computeVisibilityMap(cameraX, cameraY, cameraSightDistance, nil, nil, true)
	assert(visibilityMapTopLeftX == topLeftX)
	assert(visibilityMapTopLeftY == topLeftY)
	assert(visibilityMapWidth == self.viewportWidth)
	assert(visibilityMapHeight == self.viewportHeight)

	local function getCreatureColour(entity)
		local colour = entity.creatureType.colour
		if entity.creatureType.flashDarkerColour and self.realTime % 1 < 0.5 then
			return consts.darkerColours[colour]
		end
		return colour
	end

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
		if tileType.animationTiles then
			local animationFrame = math.floor((state.tick % (#tileType.animationTiles * tileType.animationTime)) / tileType.animationTime)
			return tileType.animationTiles[animationFrame + 1]
		elseif tileType.boxDrawingNumber then
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
					local otherType = state.tileTypes[otherTile.type]
					local sameType =
						(otherType.pretendConnectionTypeName or otherTile.type) ==
						(tileType.pretendConnectionTypeName or tile.type) or
						otherType.allowIncomingConnectionTypeNames and otherType.allowIncomingConnectionTypeNames[tileType.pretendConnectionTypeName or tile.type]
					local doorWithWall = otherTile.doorData and (tileType.pretendConnectionTypeName or tile.type) == "wall"
					local groupedAutotiling = tile.autotileGroup or otherTile.autotileGroup
					local sameGroup = tile.autotileGroup == otherTile.autotileGroup
					neighbours[direction] = otherTile and (sameType or doorWithWall) and (not groupedAutotiling or sameGroup)
					::continue::
				end
			end
	
			local right, up, left, down = getWallConnections(neighbours)
		
			if not tileType.alwaysShowConnections then
				-- Sever any connections that don't have the right visibility
				local rightMask, upMask, leftMask, downMask = false, false, false, false

				local rightEdge = isEdgeVisible(x, y, "vertical")
				if rightEdge then
					rightMask = true
					if not self:tileBlocksLight(x + 1, y, true) then
						upMask = true
						downMask = true
					end
				end
		
				local upEdge = isEdgeVisible(x, y - 1, "horizontal")
				if upEdge then
					upMask = true
					if not self:tileBlocksLight(x, y - 1, true) then
						rightMask = true
						leftMask = true
					end
				end
		
				local leftEdge = isEdgeVisible(x - 1, y, "vertical")
				if leftEdge then
					leftMask = true
					if not self:tileBlocksLight(x - 1, y, true) then
						upMask = true
						downMask = true
					end
				end
		
				local downEdge = isEdgeVisible(x, y, "horizontal")
				if downEdge then
					downMask = true
					if not self:tileBlocksLight(x, y + 1, true) then
						rightMask = true
						leftMask = true
					end
				end
		
				right = right and rightMask
				up = up and upMask
				left = left and leftMask
				down = down and downMask
			end
	
			local num = tileType.boxDrawingNumber
			local boxCharacter
			if not (right and up and left and down and tileType.no4WayJunction) then
				boxCharacter = util.getBoxDrawingCharacter(
					right and num or 0,
					up and num or 0,
					left and num or 0,
					down and num or 0
				)
			end

			if boxCharacter then
				return boxCharacter, true
			else
				return tileType.character, false
			end
		else
			return tileType.character, false
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
			cell.backgroundColour = state.tileTypes[tile.type].secondaryColour or "black"
			if tileType.darkenColour then
				local darker = consts.darkerColours[cell.foregroundColour]
				if darker then
					cell.foregroundColour = darker
				end
			end
			local box
			cell.character, box = getTileCharacter(tileX, tileY)
			if tileType.swapColours and not (box and tileType.swapColoursSingleOnly) then
				cell.foregroundColour, cell.backgroundColour = cell.backgroundColour, cell.foregroundColour
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
				if largestSpatter and largestSpatter.amount >= consts.spatterThreshold1 then
					local material = state.materials[largestSpatter.materialName]
					local matterState = material.matterState
					if tileType.liquidSpatterColourInvert and matterState == "liquid" then
						cell.backgroundColour = material.colour
					else
						cell.foregroundColour = material.colour
					end
					if tileType.solidity ~= "solid" and not (tile.liquid and matterState == "liquid") then
						if largestSpatter.amount >= consts.spatterThreshold4 then
							-- cell.character = matterState == "liquid" and "█" or "▓"
							cell.character = matterState == "liquid" and "≈" or "▒"
						elseif largestSpatter.amount >= consts.spatterThreshold3 then
							cell.character = matterState == "liquid" and "≈" or "░"
						elseif largestSpatter.amount >= consts.spatterThreshold2 then
							cell.character = matterState == "liquid" and "~" or "•"
						elseif largestSpatter.amount >= 1 and matterState == "solid" then
							cell.character = "."
						end
					end
				end
			end
			if tile.liquid then
				cell.character = "≈" -- What about a more full tile?
				cell.foregroundColour = state.materials[tile.liquid.material].colour
				cell.backgroundColour = "black"
			end

			::continue::
		end
	end

	local function getDoorDataDisplayTile(doorData)
		local dynamicDoorTileInfo = doorData.entity.itemData.itemType.dynamicDoorTileInfo
		if not dynamicDoorTileInfo then
			return nil
		end

		local closedNum = dynamicDoorTileInfo.closedLineNumber or 0
		local openNum = dynamicDoorTileInfo.openLineNumber or 0
		local closedOtherNum = dynamicDoorTileInfo.perpendicularLineNumberClosed or 0
		local openOtherNum = dynamicDoorTileInfo.perpendicularLineNumberOpen or 0

		local open = doorData.open

		local hinge = open and openNum or closedNum
		local opposite = open and openNum or closedNum
		local perpendicular1 = open and openOtherNum or closedOtherNum
		local perpendicular2 = 0

		local function cycle(n, a, b, c, d)
			for _=1, n do
				a, b, c, d = d, a, b, c
			end
			return a, b, c, d
		end

		local hingeSide = doorData.hinge

		-- For the sake of double doors opening the same way. NOTE: Could make doors open in the direction opposite to the interactor.
		if hingeSide == "up" then
			hingeSide = "down"
		elseif hingeSide == "left" then
			hingeSide = "right"
		end

		local cycleCount = hingeSide == "right" and 0 or hingeSide == "up" and 1 or hingeSide == "left" and 2 or hingeSide == "down" and 3 or 0

		local char = util.getBoxDrawingCharacter(cycle(cycleCount, hinge, perpendicular1, opposite, perpendicular2))
		return char
	end

	local indicatorTiles = {} -- To stop indicators from clashing
	local drawActionIndicators = self.realTime % 1.5 < 0.5
	local drawCursor = self.realTime % 0.5 < (commands.checkCommand("moveCursor") and not commands.checkCommand("dodgeMode") and 0.4 or 0.25)
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
			drawCharacterWorldToViewportVisibleOnly(entity.x, entity.y, "&", "darkGreen", "black")
			goto continue
		end

		if entity.entityType == "creature" then
			local foreground = getCreatureColour(entity)
			local background = entity.dead and (entity.creatureType.bloodMaterialName and state.materials[entity.creatureType.bloodMaterialName].colour or (foreground == "darkGrey" and "lightGrey" or "darkGrey")) or "black"
			drawnEntities[entity] = drawCharacterWorldToViewportVisibleOnly(entity.x, entity.y, entity.creatureType.tile, foreground, background)
			if
				drawEntityWarnings and entity ~= state.player and entity.actions[1] and
				(
					entity.actions[1].type == "shoot" or
					entity.actions[1].type == "mindAttack"
				)
			then
				drawIndicator(entity.x, entity.y, "!", "red", "black")
			end
		else
			local itemMaterial = state.materials[entity.itemData.material]
			local background = entity.itemData.itemType.secondaryColour or "black"
			local foreground = itemMaterial.colour
			if entity.itemData.itemType.swapColours then
				foreground, background = background, foreground
			end
			local tile = entity.itemData.itemType.tile
			local readMaterialTileField = entity.itemData.itemType.readMaterialTileField
			if readMaterialTileField then
				tile = itemMaterial[readMaterialTileField]
			end
			if entity.doorTile and entity.doorTile.doorData.open then
				tile = entity.itemData.itemType.openTile
			end
			if entity.doorTile and entity.doorTile.doorData then
				tile = getDoorDataDisplayTile(entity.doorTile.doorData) or tile
			end
			if entity.itemData.itemType.isButton and entity.itemData.pressed or entity.itemData.itemType.isLever and entity.itemData.active then
				tile = entity.itemData.itemType.activeTile
			end
			drawnEntities[entity] = drawCharacterWorldToViewportVisibleOnly(entity.x, entity.y, tile, foreground, background)
		end
	    ::continue::
	end

	for _, particle in ipairs(state.particles) do
		drawCharacterWorldToViewportVisibleOnly(particle.currentX, particle.currentY, particle.tile, particle.foregroundColour, particle.backgroundColour or "black")
	end
	for _, gib in ipairs(state.gibs) do
		-- Expect gibs without any flesh or blood to have been deleted
		local tile = gib.fleshAmount > 0 and gib.fleshTile or gib.bloodAmount > 10 and "•" or gib.bloodAmount >= 3 and "∙" or "·"
		local colour = state.materials[gib.fleshAmount > 0 and gib.fleshMaterial or gib.bloodMaterial].colour
		drawCharacterWorldToViewportVisibleOnly(gib.currentX, gib.currentY, tile, colour, "black")
	end
	for _, projectile in ipairs(state.projectiles) do
		if projectile.tile then
			drawCharacterWorldToViewportVisibleOnly(projectile.currentX, projectile.currentY, projectile.tile, projectile.colour, "black")
		end
	end
	for tile in pairs(state.map.explosionTiles) do
		local gradientValue = tile.explosionInfo.visual * #consts.explosionGradient / consts.explosionGradientMax
		local index = math.max(0, math.min(#consts.explosionGradient, math.floor(gradientValue + 0.5))) + 1
		local foregroundIndex = math.min(#consts.explosionGradient, index)
		local backgroundIndex = math.max(1, index - 1)
		local x, y = tile.x, tile.y
		local char = gradientValue % 1 >= 0.5 and "░" or "▒"
		if (foregroundIndex == 1 and backgroundIndex == 1) then
			char = "░"
			foregroundIndex = 2
		end
		drawCharacterWorldToViewportVisibleOnly(x, y, char, consts.explosionGradient[foregroundIndex], consts.explosionGradient[backgroundIndex])
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
		table.insert(rows, 1, {
			text = line.text,
			colour = line.announcement.colour,
			isContinuedLine = line.isContinuedLine,
			isFirstOfTick = line.announcement.isFirstOfTick,
			isFirstAfterPlayerControlLost = line.announcement.isFirstAfterPlayerControlLost
		})
		if #rows >= self.consoleHeight then
			break
		end
	end
	for rowI, row in ipairs(rows) do
		local textI = 1
		local icon
		if row.isContinuedLine then
			icon = " "
		-- elseif row.isFirstAfterPlayerControlLost then
		-- 	icon = "•"
		elseif row.isFirstOfTick then
			icon = "∙"
		else
			icon = "·"
		end
		drawCharacterFramebuffer(
			1,
			2 + self.viewportHeight + rowI - 1,
			icon,
			"darkGrey",
			"black"
		)
		for _, code in utf8.codes(row.text) do
			local char = utf8.char(code)
			drawCharacterFramebuffer(
				2 + textI - 1,
				2 + self.viewportHeight + rowI - 1,
				char,
				row.colour,
				"black"
			)
			textI = textI + 1
		end
	end

	-- Status panel

	local statusX = self.viewportWidth + 2
	local statusY = 1
	local statusWidth = self.framebufferWidth - self.viewportWidth - 3
	local statusHeight = self.framebufferHeight - self.consoleHeight - 3

	local entityStatusHeight = 6
	local function drawEntityStatus(entity, title, yShift, noText)
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
		if entity and entity.entityType == "creature" then
			drawCharacterFramebuffer(statusX + 1, statusY + 1 + yShift, entity.creatureType.tile, getCreatureColour(entity), "black")
		elseif entity and entity.entityType == "item" then
			local tile = entity.itemData.itemType.tile
			local readMaterialTileField = entity.itemData.itemType.readMaterialTileField
			if readMaterialTileField then
				tile = state.materials[entity.itemData.material][readMaterialTileField]
			end
			if entity.doorTile and entity.doorTile.doorData.open then
				tile = entity.itemData.itemType.openTile
			end
			if entity.doorTile and entity.doorTile.doorData then
				tile = getDoorDataDisplayTile(entity.doorTile.doorData) or tile
			end
			if entity.itemData.itemType.isButton and entity.itemData.pressed or entity.itemData.itemType.isLever and entity.itemData.active then
				tile = entity.itemData.itemType.activeTile
			end
			drawCharacterFramebuffer(statusX + 1, statusY + 1 + yShift, tile, util.conditionalSwap(state.materials[entity.itemData.material].colour, entity.itemData.itemType.secondaryColour or "black", entity.itemData.itemType.swapColours))
		end
		if not noText then
			drawStringFramebuffer(statusX + 3, statusY + yShift, title, titleColour, "black")
			if entity and entity.entityType == "creature" then
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
					if action.type == "shoot" or action.type == "melee" or action.type == "mindAttack" then
						actionColour = "red"
					else
						actionColour = "darkCyan"
					end
					local actionDisplayName = action.displayNameOverride or state.actionTypes[action.type].displayName
					actionInfo = util.capitalise(actionDisplayName) .. "∙" .. action.timer .. "T"
					if action.type == "move" or action.type == "melee" then
						local symbol = getOffsetSymbol(self:getDirectionOffset(action.direction))
						if action.type == "melee" and action.charge then
							symbol = "Charge" .. symbol
						end
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
				drawStringFramebuffer(statusX + 3, statusY + 1 + yShift, util.capitalise(entity.itemData.itemType.displayName, false), "lightGrey", "black")
				drawStringFramebuffer(statusX + 3, statusY + 2 + yShift, util.capitalise(state.materials[entity.itemData.material].displayName, false), "lightGrey", "black")
				local item = entity.itemData
				local itemType = item.itemType
				if itemType.isDoor then
					drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, entity.doorTile.doorData.open and "Open" or "Closed" .. (entity.doorTile.doorData.lockName and "∙Locked" or ""), "lightGrey", "black")
				elseif itemType.isLever and not (not item.active and itemType.inactiveHidden) then
					drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, item.active and "Active" or "Inactive", "lightGrey", "black")
				elseif itemType.isButton then
					drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, item.pressed and "Pressed" or "Not pressed", "lightGrey", "black")
				elseif itemType.isHealItem and not (item.itemType.healItemEndlessUse or item.itemType.healItemDeleteOnUse) then
					drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, item.healingUsed and "Used" or "Unused", "lightGrey", "black")
				elseif itemType.wearable then
					local info = self:getTotalArmourInfo(item)
					local defence = info and info.defence or 0
					local durability = info and info.durability or 0
					local wear = item.armourWear or 0
					local damageMultiplier = self:getDefenceMultiplier(defence)
					drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, "Wear: " .. wear .. "/" .. durability, "lightGrey", "black")
					drawStringFramebuffer(statusX + 1, statusY + 4 + yShift, defence .. " def∙" .. math.floor(damageMultiplier * 100 + 0.5) .. "% dmg", "lightGrey", "black")
				elseif itemType.isGun then
					local gunStatus
					if itemType.energyWeapon then
						local energyStatus = item.storedEnergy >= item.itemType.energyPerShot
						local energyStatusLine =
							(item.shotCooldownTimer and "Working" or "Ready") ..
							"∙" ..
							"Energy "
						local energyStatusChar = energyStatus and "√" or "X"
						local energyStatusColour = energyStatus and "green" or "red"
						energyStatusColour = "lightGrey"
						drawCharacterFramebuffer(statusX + 1 + utf8.len(energyStatusLine), statusY + 3 + yShift, energyStatusChar, energyStatusColour, "black")
						gunStatus =
							energyStatusLine ..
							"\n" ..
							(item.storedEnergy .. "/" .. item.itemType.maxEnergy) ..
							(item.chargeState == "fromBattery" and "«" or item.chargeState == "toBattery" and "»" or "│") ..
							(item.insertedMagazine and ("C" .. item.insertedMagazine.storedEnergy .. "/" .. item.insertedMagazine.itemType.maxEnergy) or "No cell")
					elseif itemType.displayAsDoubleShotgun then
						local a, b = item.magazineData[1], item.magazineData[2]
						gunStatus =
							(a and (a.fired and "Fired" or "Live") or "Empty") .. "∙" .. (b and (b.fired and "Fired" or "Live") or "Empty") ..
							"∙" ..
							(item.actionOpen and "Open" or "Shut") ..
							"\n" ..
							(not item.cockedStates[1] and not item.cockedStates[2] and "Both uncocked" or (item.cockedStates[1] and "Cocked" or "Uncocked") .. "∙" .. (item.cockedStates[2] and "Cocked" or "Uncocked"))
					else
						local magazineItem = item.magazineData and item or item.insertedMagazine or nil -- The gun itself, an inserted magazine, or nothing
						local nextRound = item.itemType.noChamber and magazineItem and magazineItem.magazineData[#magazineItem.magazineData] or item.chamberedRound
						gunStatus =
							(nextRound and (nextRound.fired and "Fired" or "Live") or "Empty") ..
							"∙" ..
							(item.shotCooldownTimer and "Working" or (item.itemType.noCocking and "Ready" or (item.cocked and "Cocked" or "Uncocked"))) ..
							"\n" ..
							(item.itemType.alteredMagazineUse == "ignore" and (item.itemType.breakAction and (item.actionOpen and "Open" or "Shut") or "") or (magazineItem and ("Magazine: " .. #magazineItem.magazineData .. "/" .. magazineItem.itemType.magazineCapacity) or "No magazine"))
					end
					drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, gunStatus, "lightGrey", "black")
				elseif itemType.energyBattery then
					local cellStatus = "Energy: " .. item.storedEnergy .. "/" .. item.itemType.maxEnergy
					drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, cellStatus, "lightGrey", "black")
				elseif itemType.magazine then -- Would have gone into the block above if it was a gun with its own magazine data
					local magazineStatus = "Magazine: " .. #item.magazineData .. "/" .. item.itemType.magazineCapacity
					drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, magazineStatus, "lightGrey", "black")
				elseif itemType.isAmmo then
					local ammoStatus = item.fired and "Fired" or "Live"
					drawStringFramebuffer(statusX + 1, statusY + 3 + yShift, ammoStatus, "lightGrey", "black")
				end
			end
		end
	end

	local inventoryHeight = 7
	local function drawInventory(wornItemMode)
		local indent = wornItemMode and 5 or 2
		local rectangles = {}
		for x = 0, 2 do
			for y = 0, 2 do
				rectangles[#rectangles+1] = {x = x * 4 + indent, y = y * 2 + 2 * (entityStatusHeight + 1), w = 5, h = 3}
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
		drawStringFramebuffer(statusX + 2 + indent, 2 * (entityStatusHeight + 1) + 1, "INVENTORY", "lightGrey", "black")
		if state.player and state.player.inventory then
			for i, slot in ipairs(state.player.inventory) do
				local x = statusX + (i - 1) % 3 * 4 + 2 + indent
				local y = 2 * (entityStatusHeight + 1) + 2 + math.floor((i - 1) / 3) * 2
				local isSelectedSlot = i == state.player.inventory.selectedSlot
				drawCharacterFramebuffer(x - 1, y, tostring(i), isSelectedSlot and "lightGrey" or "darkGrey", "black")
				if isSelectedSlot then
					-- drawCharacterFramebuffer(x - 1, y, "►", "lightGrey", "black")

					local n = 2
					drawCharacterFramebuffer(x - 2, y, util.getBoxDrawingCharacter(n, 1, 0, 1), "white", "black")
					drawCharacterFramebuffer(x + 2, y, util.getBoxDrawingCharacter(0, 1, n, 1), "white", "black")
				end
				if slot.item then
					local tile = slot.item.itemType.tile
					local readMaterialTileField = slot.item.itemType.readMaterialTileField
					if readMaterialTileField then
						tile = state.materials[slot.item.material][readMaterialTileField]
					end
					if slot.item.itemType.isButton and slot.item.pressed or slot.item.itemType.isLever and slot.item.active then
						tile = slot.item.itemType.activeTile
					end
					drawCharacterFramebuffer(x, y, tile, util.conditionalSwap(state.materials[slot.item.material].colour, slot.item.itemType.secondaryColour or "black", slot.item.itemType.swapColours))
					if slot.item.itemType.stackable then
						local num = self:getSlotStackSize(state.player, i)
						local str
						if num > 9 then
							-- Not supposed to happen
							str = "+"
						else
							str = tostring(num)
						end
						drawCharacterFramebuffer(x + 1, y, str, "lightGrey", "black")
					end
				end
			end
		end
	end

	drawEntityStatus(state.player and not state.player.dead and state.player or nil, "YOU", 0)
	local entity = self:getCursorEntity()
	drawEntityStatus(state.player and self:getHeldItem(state.player) and {entityType = "item", itemData = self:getHeldItem(state.player)} or nil, "POSSESSION", inventoryHeight) -- HACK
	if state.player and state.player.currentWornItem then
		if commands.checkCommand("changeWornItemMode") then
			drawInventory(true) -- Gets obscured. We just wanted the box

			local x = statusX + 1
			local y = inventoryHeight * 2 + 2

			-- Clear anything that might remain in gaps
			for x = statusX, statusX + statusWidth - 1 do
				for y = y, y + 4 do
					drawCharacterFramebuffer(x, y, " ", "black", "black")
				end
			end

			if state.player.inventory then
				-- local dropString = "»" -- "Can doff to"
				local dropString = ""
				-- for slotNumber, slot in ipairs(state.player.inventory) do
				for slotNumber = 1, 9 do
					local slot = state.player.inventory[slotNumber]
					local append
					if not slot then
						append = "·"
					elseif
						not slot.item or
						(
							self:isItemStackable(slot.item, state.player.currentWornItem) and
							self:getSlotStackSize(entity, slotNumber) < self:getMaxStackSize(slot.item)
						)
					then
						append = slotNumber
					else
						append = "∙"
					end
					dropString = dropString .. append
				end

				drawStringFramebuffer(x + statusWidth - utf8.len(dropString) - 3, y + 5, dropString, "darkGrey", "black") -- Can always doff armour to slot 0 (ground); being explicit would take more room when this was intended to be subtle
			end
			drawEntityStatus({entityType = "item", itemData = state.player.currentWornItem} or nil, "ARMOUR", inventoryHeight * 2) -- HACK
		else
			drawEntityStatus({entityType = "item", itemData = state.player.currentWornItem} or nil, nil, inventoryHeight * 2, true) -- HACK
			for x = statusX + 5, statusX + statusWidth - 1 do
				for y = inventoryHeight * 2, inventoryHeight * 2 + 6 do
					drawCharacterFramebuffer(x, y, " ", "black", "black")
				end
			end
			drawInventory(true)

			local info = self:getTotalArmourInfo(state.player.currentWornItem)
			local defence = info and info.defence or 0
			local durability = info and info.durability or 0
			local wear = state.player.currentWornItem.armourWear or 0
			local damageMultiplier = self:getDefenceMultiplier(defence)

			local x = statusX + 1
			local y = inventoryHeight * 2 + 2

			drawStringFramebuffer(x + 2, y, tostring(wear), "lightGrey", "black")
			drawStringFramebuffer(x + 2, y + 1, tostring(durability), "lightGrey", "black")
			drawStringFramebuffer(x, y + 2, tostring(defence), "lightGrey", "black")
			drawStringFramebuffer(x, y + 3, math.floor(damageMultiplier * 100 + 0.5) .. "%", "lightGrey", "black")

			-- drawStringFramebuffer(x + 2, y, tostring(math.floor(damageMultiplier * 100 + 0.5)), "lightGrey", "black")
			-- drawStringFramebuffer(x + 2, y + 1, "%D", "lightGrey", "black") -- "% of incoming damage to be taken"
			-- drawStringFramebuffer(x, y + 2, wear .. "/", "lightGrey", "black")
			-- drawStringFramebuffer(x, y + 3, " " .. durability, "lightGrey", "black")

			-- drawStringFramebuffer(x + 2, y, tostring(wear), "lightGrey", "black")
			-- drawStringFramebuffer(x + 2, y + 1, tostring(durability), "lightGrey", "black")
			-- -- drawStringFramebuffer(x, y + 2, tostring(defence), "lightGrey", "black")
			-- drawStringFramebuffer(x, y + 2, math.floor(damageMultiplier * 100 + 0.5) .. "%", "lightGrey", "black")
			-- -- drawStringFramebuffer(x, y + 3, "WORN", "lightGrey", "black")
		end
	else
		drawInventory(false)
	end
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
		if tile then
			local material = state.materials[tile.material]
			if tile.type then
				local str = util.capitalise(state.tileTypes[tile.type].displayName, false)
				if tile.liquid then
					str = str .. " & " .. state.materials[tile.liquid.material].displayName
				end
				drawStringFramebuffer(statusX + 3, statusY + yShift + 1, str, "lightGrey", "black")
			end
			if material then
				drawStringFramebuffer(statusX + 3, statusY + yShift + 2, util.capitalise(material.displayName, false), "lightGrey", "black")
			end
			if tile.type and material then
				local foreground, background = material.colour, state.tileTypes[tile.type].secondaryColour or "black"
				local char, box = getTileCharacter(tile.x, tile.y)
				if state.tileTypes[tile.type].swapColours and not (box and state.tileTypes[tile.type].swapColoursSingleOnly) then
					foreground, background = background, foreground
				end
				drawCharacterFramebuffer(statusX + 1, yShift + statusY + 1, char, foreground, background)
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
					selectedEntityIndex = self:getSelectedEntityListIndex()
					assert(selectedEntityIndex, "Selected cursor entity is not in the list of currently selectable entities")
					drawCharacterFramebuffer(statusX + 5, statusY + yShift + 3, "►", state.cursor.lockedOn and "cyan" or "yellow", "black")
				end
				local function drawEntitySymbol(entity, x, y)
					local character, colour, swap, background
					if entity.entityType == "creature" then
						character = entity.creatureType.tile
						colour = getCreatureColour(entity)
					elseif entity.entityType == "item" then
						character = entity.itemData.itemType.tile
						local readMaterialTileField = entity.itemData.itemType.readMaterialTileField
						if readMaterialTileField then
							character = state.materials[entity.itemData.material][readMaterialTileField]
						end
						if entity.doorTile and entity.doorTile.doorData.open then
							character = entity.itemData.itemType.openTile
						end
						if entity.doorTile and entity.doorTile.doorData then
							character = getDoorDataDisplayTile(entity.doorTile.doorData) or character
						end
						if entity.itemData.itemType.isButton and entity.itemData.pressed or entity.itemData.itemType.isLever and entity.itemData.active then
							character = entity.itemData.itemType.activeTile
						end
						colour = state.materials[entity.itemData.material].colour
						background = entity.itemData.itemType.secondaryColour
						swap = entity.itemData.itemType.swapColours
					end
					drawCharacterFramebuffer(x, y, character, util.conditionalSwap(colour, background or "black", swap))
				end
				local zeroX = statusX + 6
				for i, entity in ipairs(entityList) do
					local relative =  i - (selectedEntityIndex or 1)
					local separation = relative < 0 and -2 or relative > 0 and 1 or 0
					local drawX = zeroX + relative + separation
					if drawX > statusX + 1 and drawX < statusX + 10 then
						drawEntitySymbol(entity, drawX, statusY + yShift + 3)
					end
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
				local str = util.capitalise(material.displayName) .. "∙" .. largestSpatter.amount
				drawStringFramebuffer(statusX + 1, statusY + yShift + 4, str, "lightGrey", "black")
				if #tile.spatter > 1 then
					drawCharacterFramebuffer(statusX + statusWidth - 2, statusY + yShift + 4, "+", "lightGrey", "black")
				end
			else
				-- drawStringFramebuffer(statusX + 1, statusY + yShift + 4, "No spatter", "lightGrey", "black")
			end
		end
	end

	if self.drawTickTimes then
		for i, time in ipairs(self.tickTimes) do
			local x = (i - 1) * 4
			local proportion = time / consts.fixedUpdateTickLength
			local colour = proportion >= 0.5 and "red" or proportion > 0.25 and "yellow" or "green"
			if i < #self.tickTimes then
				colour = consts.darkerColours[colour]
			end
			drawStringFramebuffer(x, 0, string.format("%3s", math.floor(proportion * 100)), colour, "black")
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

function game:drawFramebufferTitle(framebuffer)
	-- Copied...
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

	local info = self.titleInfo
	local time = info.time
	local sine = math.sin(time / 2)
	-- local brightness = sine ^ 8 * util.sign(sine) * 0.5 + 0.5
	local brightness = 0.5
	-- local p = 1
	-- local brightness = 0.5 * (time < info.fireStartTime and (1 + (0.5 + 0.5 * math.cos(time * 0.5 * consts.tau / info.fireStartTime)) ^ p) or 1)
	local gradient = {"black", "darkRed", "red", "darkGrey", "lightGrey", "white"}
	for x = 0, self.framebufferWidth - 1 do
		for y = 0, self.framebufferHeight - 1 do
			local dampen = love.math.noise(x / 6, time * 1) * 0.3 + 0.6
			local noise
			do
				local time = time / 3
				noise =
					love.math.noise(x / 10, time + y / 10 / 2, time * 0.5, 0) * 0.75 +
					love.math.noise(x / 5, time * 8 + y / 5, time * 4, 10) * 0.25 +
					(love.math.noise(x / 4, time * 5 + y / 4, time * 5, 20) * 2 - 1) * 0.4
			end
			noise = math.max(0, math.min(1, noise)) * dampen
			if brightness <= 0.5 then
				noise = noise * brightness * 2
			else
				noise = 1 - (1 - noise) * (1 - brightness) * 2
			end
			local gradientSelector = 1 - y / self.framebufferHeight / math.max(0.01, noise * 1.5)
			gradientSelector = gradientSelector * #gradient
			gradientSelector = math.floor(gradientSelector)
			gradientSelector = math.min(#gradient - 1, math.max(0, gradientSelector))
			gradientSelector = gradientSelector + 1
			local darker = gradient[gradientSelector]
			local lighter = gradient[math.max(1, gradientSelector - 1)]
			local swap = noise > 0.5
			drawCharacterFramebuffer(x, y, swap and "░" or "▓", util.conditionalSwap(lighter, darker, swap))
		end
	end

	local titleY = self.framebufferHeight - 1 - 5
	for x = 0, self.framebufferWidth - 1 do
		for y = titleY, self.framebufferHeight - 1 do
			drawStringFramebuffer(x, y, " ", "black", "black")
		end
	end

	if time > info.drawTitleTime then
		local str = "M I S T R A U M A T I S M"
		local len = #str
		local x = (self.framebufferWidth - len) / 2
		x = math.floor(x)
		drawStringFramebuffer(x, titleY, str, "white", "black")
	end
end

return game
