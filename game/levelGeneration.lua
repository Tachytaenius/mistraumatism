local game = {}

function game:placeRectangle(x, y, w, h, tileType, tileMaterial)
	for x = x, x + w - 1 do
		for y = y, y + h - 1 do
			local tile = self.state.map[x][y]
			tile.type = tileType
			tile.material = tileMaterial
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
			self.state.map[x][y].autotileGroup = self.state.nextAutotileGroup
		end
	end
	self.state.nextAutotileGroup = self.state.nextAutotileGroup + 1
end

function game:carveRectangleRoom(x, y, w, h, material)
	if not self:isRectangleType(x, y, w, h, "wall") then
		self:logError("Tried to carve a room but it wasn't all wall")
		return
	end
	self:placeRectangle(x, y, w, h, "wall", material)
	self:placeRectangle(x + 1, y + 1, w - 2, h - 2, "floor", material)
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

	self:carveRectangleRoom(20, 30, 20, 26, "steel")
	self:placeCrate(24, 35, 3, 3, "crateBrown")
	self:placeCrate(27, 34, 5, 5, "crateYellow")

	self:newCreatureEntity({
		creatureTypeName = "zombie",
		team = "enemy",
		x = 30, y = 40
	})

	local spawnX, spawnY = 22, 32

	return {
		spawnX = spawnX,
		spawnY = spawnY
	}
end

return game
