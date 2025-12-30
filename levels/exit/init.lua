local levelName = (...):gsub("^levels.", "")

local info = {}

-- self is game instance
function info:createLevel() -- name should be the name of the directory containing this file. levels/levelName/init.lua
	local imageData = love.image.newImageData("levels/" .. levelName .. "/map.png")
	self:initialiseMap(imageData:getDimensions())

	local types = {
		[0x00] = "floor",
		[0x01] = "ornateFloor",
		[0x11] = "ornateCarpet",
		[0x22] = "grass",
		[0x33] = "longGrass",
		[0x44] = "wornFloor",
		[0x55] = "wall",
		[0x66] = "wornWall",
		[0x77] = "shortGrass",
		[0xaa] = "support",
		[0xbb] = "pit",
		[0xff] = "archway"
	}
	local materials = {
		[0x00] = "granite",
		[0x11] = "obsidian",
		[0x55] = "ornateCarpet",
		[0xaa] = "fescue",
		[0xbb] = "bloodRed"
	}
	local spawnX, spawnY
	local ceilingMessage = self:newTileMessage("There is a skyward hole in the cavern ceiling above\nyou. The sunlight sifts down and glints at you\nagainst the dust.", "white")
	local function decodeExtra(x, y, r, g, value, a)
		if value == 0x44 then
			self:placeTileMessage(x, y, ceilingMessage)
		elseif value == 0x55 then
			self:placeMonster(x, y, "hellNoble")
		elseif value == 0x56 then
			self:placeMonster(x, y, "behemoth")
		elseif value == 0x57 then
			self:placeMonster(x, y, "imp")
		elseif value == 0x58 then
			self:placeMonster(x, y, "demonicPriest")
		elseif value == 0x59 then
			self:placeMonster(x, y, "skeleton")
		elseif value == 0x5a then
			local priest = self:placeMonster(x, y, "demonicPriest")
			local key = self:newItemData({
				itemTypeName = "ornateKey",
				material = "bone",
				lockName = "exitArena1"
			})
			priest.inventory[1].item = key
			priest.inventory.selectedSlot = 1
		elseif value == 0x5b then
			self:placeDoorItem(x, y, "ornateDoor", "granite", false, "exitArena1")
		elseif value == 0xaa then
			self:placeItem(x, y, "flower", "borage")
		elseif value == 0xab then
			self:placeItem(x, y, "flower", "rose")
		elseif value == 0xbb then
			self:placeItem(x, y, "vines", "ivy")
		elseif value == 0xe0 then
			self:placeItem(x, y, "plasmaShotgun", "polymer")
		elseif value == 0xe1 then
			-- for _=1, 1 do
				local cell = self:placeItem(x, y, "plasmaEnergyCell", "polymer")
				cell.storedEnergy = self.state.itemTypes.plasmaEnergyCell.maxEnergy
			-- end
		elseif value == 0xe2 then
			self:placeItem(x, y, "largeMedkit", "plasticGreen")
		elseif value == 0xe3 then
			self:placeItem(x, y, "tacticalArmour", "hyperPolymer")
		elseif value == 0xe4 then
			self:placeItem(x, y, "rocketLauncher", "polymer")
		elseif value == 0xe5 then
			for _=1, 2 do
				self:placeItem(x, y, "rocket", "plasticBrown")
			end
		elseif value == 0xe6 then
			self:placeItem(x, y, "pumpShotgun", "steel")
		elseif value == 0xe7 then
			for _=1, 7 do
				self:placeItem(x, y, "buckshotShell", "plasticRed")
			end
			for _=1, 6 do
				self:placeItem(x - 1, y, "buckshotShell", "plasticRed")
			end
			for _=1, 3 do
				self:placeItem(x, y - 1, "buckshotShell", "plasticRed")
			end
			for _=1, 5 do
				self:placeItem(x, y, "slugShell", "plasticGreen")
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
