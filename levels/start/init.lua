local levelName = (...):gsub("^levels.", "")

local info = {}

-- self is game instance
function info:createLevel() -- name should be the name of the directory containing this file. levels/levelName/init.lua
	local imageData = love.image.newImageData("levels/" .. levelName .. "/map.png")
	self:initialiseMap(imageData:getDimensions())

	local types = {
		[0x00] = "floor",
		[0x55] = "wall"
	}
	local materials = {
		[0x00] = "concrete",
		[0x55] = "labTiles",
		[0xaa] = "lino"
	}
	local spawnX, spawnY
	local function decodeExtra(x, y, r, g, value, a)
		if value == 0x55 then
			self:placeDoorItem(x, y, "doorWindow", "steel", false)
		elseif value == 0xaa then
			self:placeDoorItem(x, y, "door", "steel", false)
		elseif value == 0xee then
			self:placeMonster(x, y, "zombie")
		elseif value == 0xff then
			spawnX, spawnY = x, y
		end
	end
	imageData:mapPixel(function(x, y, r, g, b, a)
		r = math.floor(r * 255 + 0.5)
		g = math.floor(g * 255 + 0.5)
		b = math.floor(b * 255 + 0.5)
		a = math.floor(a * 255 + 0.5)
		if a == 0 then
			return r, g, b, a
		end
		local tileType = types[r]
		local tileMaterial = materials[g]
		assert(tileType, "Unknown tile type encoded at " .. x .. ", " .. y .. " with " .. r .. " when creating level " .. levelName)
		assert(tileMaterial, "Unknown material type encoded at " .. x .. ", " .. y .. " with " .. g .. " when creating level " .. levelName)
		self:replaceTileInfo(x, y, {
			type = tileType,
			material = tileMaterial
		})
		decodeExtra(x, y, r, g, b, a)
		return r, g, b, a
	end)
	assert(spawnX and spawnY, "No spawn location")

	local function wardRoom(doorX, doorY, xOffsetMultiply, yOffsetMultiply)
		xOffsetMultiply = xOffsetMultiply or 1
		yOffsetMultiply = yOffsetMultiply or 1
		self:placeItem(doorX + xOffsetMultiply * 2, doorY + yOffsetMultiply * 5, "toilet", "porcelain")
		self:placeItem(doorX, doorY + yOffsetMultiply * 4, "bed", "plywood")
		self:placeItem(doorX, doorY + yOffsetMultiply * 3, "bedsideTable", "plywood")
	end

	wardRoom(59, 54)
	wardRoom(54, 54)
	wardRoom(46, 54, -1)
	wardRoom(41, 54, -1)
	wardRoom(59, 51, 1, -1)
	wardRoom(54, 51, 1, -1)
	wardRoom(46, 51, -1, -1)
	wardRoom(41, 51, -1, -1)

	self:placeItem(45, 61, "penKnife", "steel")
	self:placeNote(46, 62, "MEDICATION INVENTORY")

	self:placeItem(53, 61, "toilet", "porcelain")

	self:placeCrate(46, 61, 1, 1, "crateBrown")
	self:placeCrate(47, 62, 1, 1, "crateYellow")
	self:placeCrate(51, 58, 2, 2, "crateBrown")
	self:placeCrate(52, 57, 1, 1, "crateBrown")

	for y = 55, 56 do
		self:placeItem(48, y, "computer", "plasticBlack")
		self:placeItem(48, y, "desk", "aluminium")
		self:placeItem(49, y, "officeChair", "steel")
	end
	self:placeItem(48, 57, "filingCabinet", "steel")
	self:placeItem(48, 58, "filingCabinet", "steel")

	return {
		spawnX = spawnX,
		spawnY = spawnY
	}
end

return info
