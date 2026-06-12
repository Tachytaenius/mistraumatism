local levelName = (...):gsub("^levels.", "")

local info = {}

function info:createLevel()
	local imageData = love.image.newImageData("levels/" .. levelName .. "/map.png")
	self:initialiseMap(imageData:getDimensions())

	local function airlock(x, y, flipX)
		local xMul = flipX and -1 or 1
		self:makeAirlock({
			airDoorX = x - xMul * 1,
			airDoorY = y,
			otherDoorX = x + xMul * 1,
			otherDoorY = y,
			airDoorMaterial = "steel",
			otherDoorMaterial = "steel",
			liquidMaterial = "water",
			liquidTileCoords = {
				{x, y},
				{x + xMul * 1, y}
			},
			buttonData = {
				{x = x, y = y + 1, material = "steel"},
				{x = x - 2, y = y + 1, material = "steel"},
				{x = x + 2, y = y + 1, material = "steel"}
			}
		})
	end

	local types = {
		[0x00] = "floor",
		[0x55] = "wall",
		[0xaa] = "drain"
	}
	local materials = {
		[0x00] = "steel"
	}
	local spawnX, spawnY
	local function decodeExtra(x, y, r, g, value, a)
		if value == 0x22 then
			self:placeItem(x, y, "pistol", "steel")
			for _=1, 2 do
				self:placeMagazineWithAmmo(x, y, "pistolMagazine", "steel", "smallBullet", "brass")
			end
		elseif value == 0x33 then
			self:getTile(x, y).liquid = {material = "water"}
			self:placeMonster(x, y, "angler")
		elseif value == 0x44 then
			airlock(x, y, false)
		elseif value == 0x45 then
			airlock(x, y, true)
		elseif value == 0x55 then
			self:getTile(x, y).liquid = {material = "water"}
		elseif value == 0xaa then
			self:getTile(x, y).liquid = {material = "water"}
			self:placeCritter(x, y, love.math.random() < 0.75 and "smallFish1" or "smallFish2")
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
		self:overwriteTileInfo(x, y, {
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
