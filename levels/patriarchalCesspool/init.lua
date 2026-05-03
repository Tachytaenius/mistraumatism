local util = require("util")

local levelName = (...):gsub("^levels.", "")

local info = {}

-- self is game instance
function info:createLevel() -- name should be the name of the directory containing this file. levels/levelName/init.lua
	local totalW, totalH = 256, 256
	local imageOffsetX, imageOffsetY = 64, 64
	local imageData = love.image.newImageData("levels/" .. levelName .. "/map.png")
	local imageCentreX = imageOffsetX + imageData:getWidth() / 2
	local imageCentreY = imageOffsetY + imageData:getHeight() / 2
	self:initialiseMap(totalW, totalH)

	local types = {
		[0x00] = "wall",
		[0x11] = "floor",
		[0x22] = "pit"
	}
	local materials = {
		[0x00] = "basalt",
		[0x11] = "inflictionMagic"
	}
	local spawnX, spawnY = math.floor(imageCentreX), math.floor(imageCentreY)
	local function decodeExtra(x, y, r, g, value, a)
		if value == 0x11 then
			self:placeDoorItem(x, y, "heavyDoor", "granite", false, "noKey")
			self:placeDoorItem(x + 1, y, "heavyDoor", "granite", false, "noKey")
			local function onActivate(self, item, leverX, leverY)
				self:mechanismOpenDoor(x, y)
				self:mechanismOpenDoor(x + 1, y)
			end
			local function onDeactivate(self, item, leverX, leverY)
				self:mechanismShutDoor(x, y)
				self:mechanismShutDoor(x + 1, y)
			end
			self:placeLever(x + 2, y + 2, "steel", false, onActivate, onDeactivate)
		elseif value == 0x12 then
			self:placeDoorItem(x, y, "ornateDoor", "granite", false)
		elseif value == 0x22 then
			self:placeItem(x, y, "rocketLauncher", "polymer")
			for _=1, 7 do
				self:placeItem(x, y, "rocket", "plasticBrown")
			end

			-- self:placeItem(x + 1, y, "pistol", "steel")
			-- self:placeMagazineWithAmmo(x + 1, y, "pistolMagazine", "steel", "smallBullet", "brass")
			self:placeItem(x + 1, y, "revolverDoubleAction", "steel")
			for _=1, 12 do
				self:placeItem(x + 1, y, "mediumBullet", "brass")
			end

			self:placeItem(x, y + 1, "smallMedkit", "plasticGreen")

			-- self:placeItem(x + 1, y, "railgun", "polymer")
			-- for _=1, 9 do
			-- 	local cell = self:placeItem(x + 1, y, "railgunEnergyCell", "polymer")
			-- 	cell.storedEnergy = self.state.itemTypes.railgunEnergyCell.maxEnergy
			-- end

			-- self:placeItem(x + 1, y + 1, "plasmaRifle", "polymer")
			-- for _=1, 9 do
			-- 	local cell = self:placeItem(x + 1, y + 1, "plasmaEnergyCell", "polymer")
			-- 	cell.storedEnergy = self.state.itemTypes.plasmaEnergyCell.maxEnergy
			-- end
		elseif value == 0x33 then
			self:placeMonster(x, y, "hellKing")
		elseif value == 0xff then
			spawnX, spawnY = x, y
		end
	end
	imageData:mapPixel(function(x, y, r, g, b, a)
		local x, y = x + imageOffsetX, y + imageOffsetY

		r = math.floor(r * 255 + 0.5)
		g = math.floor(g * 255 + 0.5)
		b = math.floor(b * 255 + 0.5)
		a = math.floor(a * 255 + 0.5)
		if a == 0 then
			self:getTile(x, y).generate = true
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

	local seed = 1
	local generator = love.math.newRandomGenerator(seed)
	for x = 0, totalW - 1 do
		for y = 0, totalH - 1 do
			local tile = self:getTile(x, y)
			local generate = tile.generate or not (imageOffsetX <= x and x < imageOffsetX + imageData:getWidth() and imageOffsetY <= y and y < imageOffsetY + imageData:getHeight())
			if not generate then
				goto continue
			end

			local mat = "ice"
			local type = "frozenFloor"

			tile.material = mat
			tile.type = type

			local snowiness = love.math.noise(x / 10, y / 10) ^ 2
			self:addSpatter(x, y, "snow", math.floor(snowiness * 10))

			::continue::
		end
	end

	return {
		spawnX = spawnX,
		spawnY = spawnY
	}
end

return info
