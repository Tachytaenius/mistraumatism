local levelName = (...):gsub("^levels.", "")

local info = {}

-- self is game instance
function info:createLevel()
	local imageData = love.image.newImageData("levels/" .. levelName .. "/map.png")
	self:initialiseMap(imageData:getDimensions())

	local types = {
		[0x00] = "floor",
		[0x11] = "roughFloor",
		[0x22] = "pit",
		[0x28] = "archway",
		[0x29] = "archwayLeft",
		[0x2a] = "archwayRight",
		[0x33] = "drawbridgeVertical",
		[0x34] = "openHatch",
		[0x44] = "diningTable",
		[0x45] = "hugeBookshelf",
		[0x55] = "brickWall",
		[0x56] = "support",
		[0x57] = "wall",
		[0x66] = "arrowSlit",
		[0x77] = "glassWindow",
		[0xaa] = "turf",
		[0xbb] = "flowerbed",
		[0xcc] = "livingFloor",
		[0xdd] = "livingWall",
		[0xff] = "ornateCarpet"
	}
	local materials = {
		[0x00] = "granite",
		[0x22] = "mahogany",
		[0x55] = "marbleGreen",
		[0x56] = "marble",
		[0x66] = "mahogany",
		[0xaa] = "grass",
		[0xbb] = "soilLoamless",
		[0xcc] = "fleshRed",
		[0xff] = "ornateCarpet"
	}
	local spawnX, spawnY
	local leversToPlace = {}
	local leverDoors = {}
	local secretLibraryBookDoorCoord
	local function decodeExtra(x, y, r, g, value, a)
		if value == 0x22 then
			self:placeExaminable(x, y, "statue2", "marble", "The statue's smug self-complicity angers your animal\nheart. It is vile.")
		elseif value == 0x23 then
			self:placeExaminable(x, y, "statue2", "marble", "The statue depicts a deeply insulting scene.\nYou feel terrible.")
		elseif value == 0x24 then
			self:placeExaminable(x, y, "statue1", "marble", "This statue was not made by compassionate hands...\nHow could anyone be so cruel to feel such a thing?")
		elseif value == 0x25 then
			self:placeExaminable(x, y, "statue1", "marble", "You avert your gaze. The statue makes you sick.")
		elseif value == 0x26 then
			self:placeExaminable(x, y, "statue1", "marble", "This art is a form of violence.")
		elseif value == 0x27 then
			self:placeExaminable(x, y, "statue1", "marble", "Whoever created the sculpture wanted to cause harm.\nIt may be a masterpiece, but it has no value.")
		elseif value == 0x28 then
			self:placeDoorItem(x, y, "ornateDoor", "mahogany", false)
		elseif value == 0x29 then
			self:placeItem(x, y, "altar", "granite")
		elseif value == 0x2a then
			self:placeExaminable(x, y, "statue2", "granite", "They worship an icon of abuse.")
		elseif value == 0x2c then
			self:placeDoorItem(x, y, "heavyDoor", "mahogany", false)
			secretLibraryBookDoorCoord = {x = x, y = y}
		elseif value == 0x2d then
			leversToPlace[#leversToPlace+1] = function()
				local function onActivate(self, item, x, y)
					self:mechanismOpenDoor(secretLibraryBookDoorCoord.x, secretLibraryBookDoorCoord.y)
				end
				local function onDeactivate(self, item, x, y)
					self:mechanismShutDoor(secretLibraryBookDoorCoord.x, secretLibraryBookDoorCoord.y)
				end
				self:placeLever(x + 5, y + 2, "leather", false, onActivate, onDeactivate, nil, nil, "leverBook")
			end
			self:placeExaminable(x + 1, y + 4, "largeBook", "gold", "It's a torture manual... The techniques listed would\ncause unimaginable pain.")
			self:placeExaminable(x + 2, y + 2, "book", "leather", "It's the first volume of a novel entitled \"Spoils\".")
			self:placeExaminable(x + 2, y + 2, "book", "leather", "It's the second volume of a novel entitled \"Spoils\".")
			self:placeExaminable(x + 3, y + 2, "book", "leather", "It's the third volume of a novel entitled \"Spoils\".")
			self:placeExaminable(x + 2, y, "smallBook", "leather", "The book's title is \"Violate\". You daren't open it.")
		elseif value == 0x3b then
			leverDoors[#leverDoors+1] = {x = x, y = y}
			self:placeDoorItem(x, y, "castleDoorLeft", "mahogany", false)
		elseif value == 0x3c then
			self:placeDoorItem(x, y, "castleDoorLeft", "mahogany", true)
		elseif value == 0x3d then
			self:placeItem(x, y, "ornateChair", "mahogany")
		elseif value == 0x3e then
			self:placeItem(x, y, "ornateDesk", "mahogany")
		elseif value == 0x54 then
			leverDoors[#leverDoors+1] = {x = x, y = y}
			self:placeDoorItem(x, y, "castleDoorRight", "mahogany", false)
		elseif value == 0x55 then
			self:placeDoorItem(x, y, "castleDoorRight", "mahogany", true)
		elseif value == 0x99 then
			self:placeMonster(x, y, "imp")
		elseif value == 0x9a then
			self:placeMonster(x, y, "zombie")
		elseif value == 0xaa then
			self:placeMonster(x, y, "hellNoble")
			self:placeItem(x, y, "throne", "gold")
		elseif value == 0xab then
			self:placeMonster(x, y, "hellNoble")
		elseif value == 0xbb then
			self:placeMonster(x, y, "skeleton", "scythe", "iron")
		elseif value == 0xcc then
			self:placeItem(x, y, "flower", "roseWithered")
			self:placeItem(x, y, "flower", "roseWithered")
		elseif value == 0xcd then
			self:placeItem(x, y, "gallows", "mahogany")
		elseif value == 0xce then
			local _, gallowsEntity = self:placeItem(x, y, "gallows", "mahogany")
			local corpse = self:placeCorpseTeam(x, y, "human", "person")
			corpse.hangingFrom = gallowsEntity
			corpse.blood = 0
			corpse.bleedingAmount = 8
			corpse.health = 4 -- Dead, so this just represents mangling level. They were killed by hanging, not before it, so this can't be <= 0
		elseif value == 0xcf then
			self:addSpatter(x, y, "bloodRed", love.math.random(1, 2))
		elseif value == 0xd0 then
			leversToPlace[#leversToPlace+1] = function()
				local hatches = {}
				for ox = -4, 4 do
					local tile = self:getTile(x + ox, y)
					if tile and tile.type == "openHatch" or tile.type == "closedHatch" then
						hatches[#hatches+1] = tile
					end
				end
				local function onActivate(self, item, x, y)
					for _, tile in ipairs(hatches) do
						tile.type = "openHatch"
						self:broadcastHatchStateChangedEvent(tile, nil, false)
					end
				end
				local function onDeactivate(self, item, x, y)
					for _, tile in ipairs(hatches) do
						tile.type = "closedHatch"
						self:broadcastHatchStateChangedEvent(tile, nil, false)
					end
				end
				self:placeLever(x, y, "iron", true, onActivate, onDeactivate)
			end
		elseif value == 0xd1 then
			leversToPlace[#leversToPlace+1] = function()
				local function onActivate(self, item, x, y)
					for _, coord in ipairs(leverDoors) do
						self:mechanismOpenDoor(coord.x, coord.y)
					end
				end
				local function onDeactivate(self, item, x, y)
					for _, coord in ipairs(leverDoors) do
						self:mechanismShutDoor(coord.x, coord.y)
						end
				end
				self:placeLever(x, y, "iron", false, onActivate, onDeactivate)
			end
		elseif value == 0xdd then
			self:placeItem(x, y, "flower", "roseWithered")
		elseif value == 0xec then
			self:placeItem(x, y, "dagger", "iron")
		elseif value == 0xed then
			for _= 1, 16 do
				self:placeItem(x, y, "buckshotShell", "plasticRed")
			end
		elseif value == 0xee then
			self:placeItem(x, y, "huntingShotgun", "steel")
		elseif value == 0xef then
			self:placeItem(x, y, "bandage", "cloth")
		elseif value == 0xf0 then
			self:placeNote(x, y, "TODO: Armour?")
		elseif value == 0xf1 then
			self:placeItem(x, y, "rocket", "plasticBrown")
		elseif value == 0xf2 then
			self:placeItem(x, y, "rocketLauncher", "polymer")
		elseif value == 0xf3 then
			self:placeExaminable(x, y, "smallBook", "ginkgo", "It seems to be a benevolent book of spells...\nBut whose was it?")
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
	for _, func in ipairs(leversToPlace) do
		func()
	end

	return {
		spawnX = spawnX,
		spawnY = spawnY
	}
end

return info
