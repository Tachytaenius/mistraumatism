local levelName = (...):gsub("^levels.", "")

local info = {}

-- self is game instance
function info:createLevel() -- name should be the name of the directory containing this file. levels/levelName/init.lua
	local imageData = love.image.newImageData("levels/" .. levelName .. "/map.png")
	self:initialiseMap(imageData:getDimensions())

	local types = {
		[0x00] = "floor",
		[0x11] = "pit",
		[0x12] = "floorPortal1",
		[0x13] = "floorPortal2",
		[0x14] = "floorPortal3",
		[0x22] = "roughFloor",
		[0x44] = "labTilesWall",
		[0x55] = "wall",
		[0x66] = "support",
		[0x77] = "glassWindow",
		[0xaa] = "drain",
		[0xbb] = "heavyPipes",
		[0xcc] = "lightPipes",
		[0xdd] = "horizontalConveyorBelt",
		[0xde] = "verticalConveyorBelt",
		[0xed] = "conveyorIO",
		[0xee] = "controlPanel",
		[0xef] = "machineCasing",
		[0xf0] = "floorWiring",
		[0xf1] = "wallWiring",
		[0xf2] = "floorGrating",
		[0xf3] = "shelving",
		[0xf4] = "hazardTape",
		[0xff] = "meshWall"
	}
	local materials = {
		[0x00] = "concrete",
		[0x11] = "bloodRed",
		[0x22] = "granite",
		[0x33] = "inflictionMagic",
		[0x44] = "porcelain",
		[0x55] = "plaster",
		[0xaa] = "lino",
		[0xbb] = "copper",
		[0xcc] = "plasticBlack",
		[0xfd] = "plasticYellow",
		[0xfe] = "aluminium",
		[0xff] = "steel"
	}
	local spawnX, spawnY
	local function decodeExtra(x, y, r, g, value, a)
		if value == 0x22 then
			self:placeItem(x, y, "bench", "plywood")
		elseif value == 0x23 then
			self:placeItem(x, y, "bigPlantPot", "plasticBrown")
			self:placeItem(x, y, "sapling", "palm")
		elseif value == 0x33 then
			self:placeItem(x, y, "bandage", "cloth")
		elseif value == 0x34 then
			self:placeItem(x, y, "pistol", "steel")
		elseif value == 0x35 then
			self:placeMagazineWithAmmo(x, y, "pistolMagazine", "steel", "smallBullet", "brass", 2)
			for _=1, 2 do
				self:placeItem(x, y, "smallBullet", "brass")
			end
			self:placeItem(x + 1, y, "smallBullet", "brass")
			self:addSpatter(x, y, "bloodRed", 2)
		elseif value == 0x36 then
			self:placeItem(x, y, "sawnShotgun", "steel")
			for _=1, 5 do
				self:placeItem(x, y - 1, "buckshotShell", "plasticRed")
			end
		elseif value == 0x37 then
			for _=1, 3 do
				self:placeItem(x, y, "buckshotShell", "plasticRed")
			end
		elseif value == 0x55 then
			self:placeDoorItem(x, y, "doorWindow", "steel", false)
		elseif value == 0x56 then
			self:placeDoorItem(x, y, "doorWindow", "steel", true)
		elseif value == 0xaa then
			self:placeDoorItem(x, y, "door", "steel", false)
		elseif value == 0xab then
			self:placeDoorItem(x, y, "door", "steel", true)
		elseif value == 0xac then
			self:placeDoorItem(x, y, "door", "steel", false, "facilityCorpseStorage")
		elseif value == 0xad then
			self:placeKey(x, y, "keycard", "plasticRed", "facilityCorpseStorage")
		elseif value == 0xea then
			self:placeMonster(x, y, "brutePhantom")
		elseif value == 0xeb then
			self:placeMonster(x, y, "griefPhantom")
		elseif value == 0xec then
			self:placeCorpseTeam(x, y, "zombie", "monster")
		elseif value == 0xed then
			self:placeMonster(x, y, "ogre")
		elseif value == 0xee then
			self:placeMonster(x, y, "zombie")
		elseif value == 0xef then
			self:addSpatter(x, y, "bloodRed", 3)
		elseif value == 0xf0 then
			self:addSpatter(x, y, "bloodRed", 1)
		elseif value == 0xf1 then
			self:addSpatter(x, y, "bloodRed", 4)
			self:placeDoorItem(x, y, "doorWindow", "steel", false)
		elseif value == 0xf2 then
			local tile = self:getTile(x, y)
			tile.fallLevelChange = "hellCastle"
		elseif value == 0xf3 then
			self:placeNote(x, y, "PRODUCTION REPORT\nTotal yield: 1.2 kL\nResistance: minimal")
		elseif value == 0xf4 then
			self:placeCrate(x, y, 1, 1, "plasticBrown")
		elseif value == 0xf5 then
			self:placeCrate(x, y, 2, 1, "plasticYellow")
		elseif value == 0xf6 then
			self:placeNote(x, y, "QUOTA CHECKLIST")
			local corpse = self:placeCorpseTeam(x, y, "zombie", "monster")
			corpse.blood = math.max(0, corpse.creatureType.maxBlood - 9)
			self:addSpatter(x, y, "bloodRed", 4)
			self:addSpatter(x + 1, y, "bloodRed", 2)
			self:addSpatter(x, y + 1, "bloodRed", 2)
			self:addSpatter(x, y + 2, "bloodRed", 1)
		elseif value == 0xf8 then
			self:placeItem(x, y, "labTable", "steel")
		elseif value == 0xf9 then
			self:addSpatter(x, y, "granite", 3)
		elseif value == 0xfa then
			self:addSpatter(x, y, "granite", 2)
		elseif value == 0xfb then
			self:placeItem(x, y, "labTable", "steel")
			self:addSpatter(x, y, "bloodRed", 5)
		elseif value == 0xff then
			spawnX, spawnY = x, y
		end
	end
	local extras = {}
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
		table.insert(extras, {x, y, r, g, b, a})
		return r, g, b, a
	end)
	for _, extra in ipairs(extras) do
		decodeExtra(unpack(extra))
	end
	assert(spawnX and spawnY, "No spawn location")

	local function wardRoom(doorX, doorY, xOffsetMultiply, yOffsetMultiply)
		xOffsetMultiply = xOffsetMultiply or 1
		yOffsetMultiply = yOffsetMultiply or 1
		self:placeItem(doorX + xOffsetMultiply * 2, doorY + yOffsetMultiply * 4, "toilet", "porcelain")
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

	self:placeItem(45, 61, "boxCutter", "steel")
	self:placeNote(46, 62, "MEDICATION INVENTORY")

	self:placeItem(53, 61, "toilet", "porcelain")

	self:placeCrate(46, 61, 1, 1, "plasticBrown")
	self:placeCrate(47, 62, 1, 1, "plasticYellow")
	self:placeCrate(51, 58, 2, 2, "plasticBrown")
	self:placeCrate(52, 57, 1, 1, "plasticBrown")

	for y = 55, 56 do
		self:placeItem(48, y, "computer", "plasticBlack")
		self:placeItem(48, y, "desk", "aluminium")
		self:placeItem(49, y, "officeChair", "steel")
	end
	self:placeItem(48, 57, "filingCabinet", "aluminium")
	self:placeItem(48, 58, "filingCabinet", "aluminium")

	-- Make the corpse storage cages.
	-- But they should be the same every time, so we'll use a random generator with a set seed.
	local rng = love.math.newRandomGenerator(0)
	local function makeGoreCage(goreX, goreY, goreWidth, goreHeight, goreMultiplier, noCorpses)
		for ox = 0, goreWidth - 1 do
			for oy = 0, goreHeight - 1 do
				local x, y = ox + goreX, oy + goreY
				-- local goreMultiplier = (oy / goreHeight) ^ 0.4
				local baseBloodAmount = math.floor(goreMultiplier * 10)
				local bloodAmount = baseBloodAmount + rng:random(0, 3)
				self:addSpatter(x, y, "bloodRed", bloodAmount)

				if noCorpses or not self:getWalkable(x, y) then
					goto continue
				end

				local baseCorpseAmount = math.floor(goreMultiplier * 3)
				local corpseAmount = baseCorpseAmount + rng:random(0, 2)
				for _=1, corpseAmount do
					if rng:random() < 0.4 then
						local skeleton = rng:random() < 0.125
						local corpse = self:placeCorpseTeam(x, y, skeleton and "skeleton" or "human", "person")
						if not skeleton then
							corpse.blood = 0
							corpse.bleedingAmount = rng:random(4, 16)
						end
						corpse.health = rng:random(skeleton and -1 or -5, 0)
					end
					if rng:random() < 0.5 then
						local fleshAmount = rng:random(1, 8)
						self:addSpatter(x, y, "fleshRed", fleshAmount)
					end
				end

			    ::continue::
			end
		end
	end
	makeGoreCage(87, 18, 3, 5, 0.6, false)
	makeGoreCage(95, 16, 5, 4, 0.8, false)
	makeGoreCage(94, 25, 4, 3, 0.2, true)

	self:placeCrate(70, 31, 5, 5, "plasticBrown")
	self.state.map[72][31].type = "conveyorIO"

	self:placeCrate(66, 33, 3, 4, "plasticYellow")
	self:placeCrate(76, 34, 1, 1, "plasticYellow")
	self:placeCrate(67, 39, 3, 2, "plasticYellow")
	self:placeCrate(72, 38, 3, 3, "plasticBrown")
	self:placeCrate(71, 42, 2, 3, "plasticBrown")
	self:placeCrate(66, 44, 2, 2, "plasticYellow")
	self:placeCrate(70, 47, 1, 1, "plasticBrown")
	self:placeCrate(75, 47, 1, 1, "plasticBrown")
	self:placeCrate(75, 48, 1, 1, "plasticYellow")
	-- self:placeCrate(71, 46, 4, 3, "plasticBrown")
	self:placeCrate(79, 39, 1, 1, "plasticBrown")
	self:placeCrate(78, 40, 1, 1, "plasticYellow")
	self:placeCrate(77, 41, 1, 1, "plasticBrown")
	self:placeCrate(78, 42, 1, 1, "plasticYellow")
	self:placeCrate(79, 44, 1, 1, "plasticYellow")
	self:placeCrate(79, 45, 1, 1, "plasticYellow")
	self:placeCrate(78, 45, 1, 1, "plasticBrown")
	self:placeCrate(78, 46, 1, 1, "plasticBrown")
	self:placeCrate(77, 47, 1, 1, "plasticYellow")

	return {
		spawnX = spawnX,
		spawnY = spawnY
	}
end

return info
