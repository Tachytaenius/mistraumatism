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

function game:placeCrate(x, y, w, h, material)
	if not self:isRectangleType(x, y, w, h, "floor") then
		self:logError("Tried to place a crate but it wasn't all floor")
		return
	end
	self:placeRectangle(x, y, w, h, "wall", material)
	self:placeRectangle(x + 1, y + 1, w - 2, h - 2, "floor", material)
	for x = x, x + w - 1 do
		for y = y, y + h - 1 do
			-- Not replacing
			self.state.map[x][y].autotileGroup = self.state.nextAutotileGroup
		end
	end
	self.state.nextAutotileGroup = self.state.nextAutotileGroup + 1
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

function game:placeMonster(x, y, creatureTypeName)
	return self:newCreatureEntity({
		creatureTypeName = creatureTypeName,
		team = "monster",
		x = x, y = y
	})
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

function game:generateLevel(parameters)
	local state = self.state
	local map = {}
	state.map = map
	map.width = 128
	map.height = 128
	for x = 0, map.width - 1 do
		map[x] = {}
		for y = 0, map.height - 1 do
			local newTile = {}
			newTile.x = x
			newTile.y = y
			newTile.type = "wall"
			newTile.material = "stone"
			map[x][y] = newTile
		end
	end

	local spawnX, spawnY = 43, 34
	for _=1, 5 do
		self:placeItem(45, 34, "shotgunShell", "plasticRed")
	end
	self:placeItem(45, 33, "pumpShotgun", "steel")
	self:carveRectangleRoom(30, 30, 9, 9, "labTiles", "concrete")
	self:carveRectangleRoom(40, 31, 7, 7, "labTiles", "concrete")
	self:carveRectangleRoom(38, 33, 3, 3, "labTiles", "concrete")
	self:placeRectangle(38, 34, 3, 1, "floor", "concrete")
	self:randomSpatterRectangleDistribute(30, 30, 9, 9, "bloodRed", 32)

	self:placeDoorItem(39, 34, "door", "steel", false)

	self:placeItem(32, 32, "labTable", "steel")
	self:placeItem(32, 33, "labTable", "steel")
	self:placeItem(32, 35, "labTable", "steel")
	self:placeItem(32, 36, "labTable", "steel")

	self:placeItem(34, 32, "labTable", "steel")
	self:placeItem(34, 33, "labTable", "steel")
	self:placeItem(34, 35, "labTable", "steel")
	self:placeItem(34, 36, "labTable", "steel")

	self:placeItem(36, 32, "labTable", "steel")
	self:placeItem(36, 33, "labTable", "steel")
	self:placeItem(36, 35, "labTable", "steel")
	self:placeItem(36, 36, "labTable", "steel")

	return {
		spawnX = spawnX,
		spawnY = spawnY
	}
end

return game
