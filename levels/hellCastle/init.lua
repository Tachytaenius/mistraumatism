local levelName = (...):gsub("^levels.", "")

local info = {}

-- self is game instance
function info:createLevel()
	local imageData = love.image.newImageData("levels/" .. levelName .. "/map.png")
	self:initialiseMap(imageData:getDimensions())

	local types = {
		[0x00] = "floor",
		[0x22] = "pit",
		[0x28] = "archway",
		[0x33] = "drawbridgeVertical",
		[0x55] = "wall",
		[0x66] = "arrowSlit",
		[0x77] = "glassWindow",
		[0xaa] = "turf",
		[0xbb] = "flowerbed",
		[0xff] = "ornateCarpet"
	}
	local materials = {
		[0x00] = "stone",
		[0x22] = "wood",
		[0x55] = "stoneGreen",
		[0xaa] = "grass",
		[0xbb] = "soilLoamless",
		[0xff] = "ornateCarpet"
	}
	local spawnX, spawnY
	local function decodeExtra(x, y, r, g, value, a)
		if value == 0x28 then
			self:placeDoorItem(x, y, "door", "wood", false)
		elseif value == 0x3c then
			self:placeDoorItem(x, y, "castleDoorLeft", "wood", true)
		elseif value == 0x55 then
			self:placeDoorItem(x, y, "castleDoorRight", "wood", true)
		elseif value == 0x99 then
			self:placeMonster(x, y, "imp")
		elseif value == 0xaa then
			self:placeItem(x, y, "throne", "gold")
			self:placeMonster(x, y, "hellNoble")
		elseif value == 0xbb then
			self:placeMonster(x, y, "skeleton")
		elseif value == 0xcc then
			self:placeItem(x, y, "flower", "roseWithered")
			self:placeItem(x, y, "flower", "roseWithered")
		elseif value == 0xdd then
			self:placeItem(x, y, "flower", "roseWithered")
		elseif value == 0xee then
			self:placeItem(x, y, "huntingShotgun", "steel")
			for _= 1, 16 do
				self:placeItem(x, y, "buckshotShell", "plasticRed")
			end
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

	return {
		spawnX = spawnX,
		spawnY = spawnY
	}
end

return info
