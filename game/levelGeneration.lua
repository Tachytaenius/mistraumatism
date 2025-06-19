local game = {}

function game:replaceTileInfo(x, y, info)
	local tile = self:getTile(x, y)
	if not tile then
		return
	end
	for k in pairs(tile) do -- Preserve links
		tile[k] = nil
	end
	tile.x = x
	tile.y = y
	for k, v in pairs(info) do
		tile[k] = v
	end
end

function game:placeRectangle(x, y, w, h, tileType, tileMaterial)
	for x = x, x + w - 1 do
		for y = y, y + h - 1 do
			self:replaceTileInfo(x, y, {
				type = tileType,
				material = tileMaterial
			})
		end
	end
end

function game:isRectangleType(x, y, w, h, type)
	for x = x, x + w - 1 do
		for y = y, y + h - 1 do
			if self.state.map[x][y].type ~= type then
				return false
			end
		end
	end
	return true
end

function game:getAutotileGroupId()
	local ret = self.state.nextAutotileGroup
	self.state.nextAutotileGroup = self.state.nextAutotileGroup + 1
	return ret
end

function game:placeCrate(x, y, w, h, material)
	if not self:isRectangleType(x, y, w, h, "floor") then
		self:logError("Tried to place a crate but it wasn't all floor")
		return
	end
	self:placeRectangle(x, y, w, h, "crateWall", material)
	self:placeRectangle(x + 1, y + 1, w - 2, h - 2, "floor", material)
	local crateGroup = self:getAutotileGroupId()
	for x = x, x + w - 1 do
		for y = y, y + h - 1 do
			-- Not replacing
			self.state.map[x][y].autotileGroup = crateGroup
		end
	end
end

function game:carveRectangleRoom(x, y, w, h, material, floorMaterial)
	if not self:isRectangleType(x, y, w, h, "wall") then
		self:logError("Tried to carve a room but it wasn't all wall")
		return
	end
	self:placeRectangle(x, y, w, h, "wall", material)
	self:placeRectangle(x + 1, y + 1, w - 2, h - 2, "floor", floorMaterial or material)
end

function game:placeItem(x, y, itemTypeName, material)
	local entity = self:newItemEntity(x, y, self:newItemData({
		itemTypeName = itemTypeName,
		material = material
	}))
	return entity.itemData, entity
end

function game:placeCreatureTeam(x, y, creatureTypeName, team)
	local entity = self:newCreatureEntity({
		creatureTypeName = creatureTypeName,
		team = team,
		x = x, y = y
	})
	if entity.creatureType.spawnItemType and entity.creatureType.inventorySize >= 1 then
		entity.inventory[1].item = self:newItemData({itemTypeName = entity.creatureType.spawnItemType, material = entity.creatureType.spawnItemMaterial})
		entity.inventory.selectedSlot = 1
	end
	return entity
end

function game:placeMonster(x, y, creatureTypeName)
	return self:placeCreatureTeam(x, y, creatureTypeName, "monster")
end

function game:placeCritter(x, y, creatureTypeName)
	return self:placeCreatureTeam(x, y, creatureTypeName, "critter")
end

function game:placeDoorItem(x, y, itemTypeName, material, open)
	local tile = self:getTile(x, y)
	if not tile then
		return
	end
	if tile.doorItem then
		return
	end
	local doorItem = self:newItemData({
		itemTypeName = itemTypeName,
		material = material
	})
	local doorEntity = self:newItemEntity(x, y, doorItem, {doorTile = tile})
	tile.doorData = {entity = doorEntity, open = open}
	return doorEntity
end

function game:randomSpatterRectangleDistribute(x, y, w, h, material, amount)
	for _=1, amount do
		self:addSpatter(love.math.random(x, x + w - 1), love.math.random(y, y + h - 1), material, 1)
	end
end

function game:randomSpatterRectangleChoose(x, y, w, h, material, maxAmount)
	for x = x, x + w - 1 do
		for y = y, y + h - 1 do
			self:addSpatter(x, y, material, love.math.random(0, maxAmount))
		end
	end
end

function game:placeNote(x, y, text, startLineBreak)
	local item, entity = self:placeItem(x, y, "note", "paper")
	item.writtenText = text
	item.writtenTextStartLineBreak = startLineBreak
end

function game:placeButton(x, y, material, onPress, onUnpress)
	local item = self:placeItem(x, y, "button", material)
	item.onPress = onPress
	item.onUnpress = onUnpress
end

function game:getAirlockOnPress(airlockInfo)
	return function(self, item, x, y)
		-- TODO: Delay
		if airlockInfo.airDoorOpen then
			if self:isDoorBlocked(airlockInfo.airDoor) then
				return
			end
			if airlockInfo.airDoor.doorTile then
				airlockInfo.airDoor.doorTile.doorData.open = false
			end
			if airlockInfo.otherDoor.doorTile then
				airlockInfo.otherDoor.doorTile.doorData.open = true
			end
			if airlockInfo.liquidMaterial then
				for _, tile in ipairs(airlockInfo.liquidTiles) do
					tile.liquid = {material = airlockInfo.liquidMaterial}
				end
			end
		else
			if self:isDoorBlocked(airlockInfo.otherDoor) then
				return
			end
			if airlockInfo.otherDoor.doorTile then
				airlockInfo.otherDoor.doorTile.doorData.open = false
			end
			if airlockInfo.airDoor.doorTile then
				airlockInfo.airDoor.doorTile.doorData.open = true
			end
			if airlockInfo.liquidMaterial then
				for _, tile in ipairs(airlockInfo.liquidTiles) do
					tile.liquid = nil
				end
			end
		end
		airlockInfo.airDoorOpen = not airlockInfo.airDoorOpen
	end
end

function game:makeAirlock(params)
	local info = {}
	-- TODO: Initial state from parameters
	info.airDoorOpen = false
	info.airDoor = self:placeDoorItem(params.airDoorX, params.airDoorY, "airlockDoor", params.airDoorMaterial, false)
	info.otherDoor = self:placeDoorItem(params.otherDoorX, params.otherDoorY, "airlockDoor", params.otherDoorMaterial, true)
	info.liquidMaterial = params.liquidMaterial
	info.liquidTiles = {}
	for i, coord in ipairs(params.liquidTileCoords) do
		local tile = self:getTile(coord[1], coord[2])
		info.liquidTiles[i] = tile
		assert(tile, "No tile to be marked for airlock liquid at " .. coord[1] .. ", " .. coord[2])
	end
	if params.liquidMaterial then
		for _, tile in ipairs(info.liquidTiles) do
			tile.liquid = {material = info.liquidMaterial}
		end
	end
	local pressFunction = self:getAirlockOnPress(info)
	for _, buttonInfo in ipairs(params.buttonData) do
		self:placeButton(buttonInfo.x, buttonInfo.y, buttonInfo.material, pressFunction)
	end
	self.state.airlockData[#self.state.airlockData+1] = info
end

function game:initialiseMap(width, height)
	local group = self:getAutotileGroupId()
	local state = self.state
	local map = {}
	state.map = map
	map.width = width
	map.height = height
	for x = 0, map.width - 1 do
		map[x] = {}
		for y = 0, map.height - 1 do
			local newTile = {}
			newTile.x = x
			newTile.y = y
			newTile.type = "roughWall"
			newTile.material = "stone"
			newTile.autotileGroup = group
			map[x][y] = newTile
		end
	end

	map.explosionTiles = {}
	map.spatteredTiles = {}
end

function game:generateLevel(parameters)
	local info = require("levels." .. parameters.levelName)
	return info.createLevel(self)
end

return game
