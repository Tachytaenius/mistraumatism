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
		[0x55] = "labTiles"
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

	self:placeItem(spawnX, spawnY, "pumpShotgun", "steel")
	for _=1, 6 do
		self:placeItem(spawnX, spawnY, "shotgunShell", "plasticRed")
	end

	return {
		spawnX = spawnX,
		spawnY = spawnY
	}
end

return info
