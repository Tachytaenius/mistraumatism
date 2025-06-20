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
		[0x00] = "stone",
		[0x22] = "wood",
		[0x55] = "stoneGreen",
		[0x66] = "wood",
		[0xaa] = "grass",
		[0xbb] = "soilLoamless",
		[0xcc] = "fleshRed",
		[0xff] = "ornateCarpet"
	}
	local spawnX, spawnY
	local leversToPlace = {}
	local leverDoors = {}
	local function decodeExtra(x, y, r, g, value, a)
		if value == 0x22 then
			self:placeExaminable(x, y, "statue2", "stone", "The statue's smug self-complicity angers your animal\nheart. It is vile.")
		elseif value == 0x23 then
			self:placeExaminable(x, y, "statue2", "stone", "The statue depicts a deeply insulting scene.\nYou feel terrible.")
		elseif value == 0x24 then
			self:placeExaminable(x, y, "statue1", "stone", "This statue was not made by compassionate hands...\nHow could anyone be so cruel to feel such a thing?")
		elseif value == 0x25 then
			self:placeExaminable(x, y, "statue1", "stone", "You avert your gaze. The statue makes you sick.")
		elseif value == 0x26 then
			self:placeExaminable(x, y, "statue1", "stone", "This art is a form of violence.")
		elseif value == 0x27 then
			self:placeExaminable(x, y, "statue1", "stone", "Whoever created the sculpture wanted to cause harm.\nIt may be a masterpiece, but it has no value.")
		elseif value == 0x28 then
			self:placeDoorItem(x, y, "door", "wood", false)
		elseif value == 0x29 then
			self:placeItem(x, y, "altar", "stone")
		elseif value == 0x2a then
			self:placeExaminable(x, y, "statue2", "stone", "They worship an icon of abuse.")
		elseif value == 0x3b then
			leverDoors[#leverDoors+1] = {x = x, y = y}
			self:placeDoorItem(x, y, "castleDoorLeft", "wood", false)
		elseif value == 0x3c then
			self:placeDoorItem(x, y, "castleDoorLeft", "wood", true)
		elseif value == 0x3d then
			self:placeItem(x, y, "ornateChair", "wood")
		elseif value == 0x54 then
			leverDoors[#leverDoors+1] = {x = x, y = y}
			self:placeDoorItem(x, y, "castleDoorRight", "wood", false)
		elseif value == 0x55 then
			self:placeDoorItem(x, y, "castleDoorRight", "wood", true)
		elseif value == 0x99 then
			self:placeMonster(x, y, "imp")
		elseif value == 0xaa then
			self:placeItem(x, y, "throne", "gold")
			self:placeMonster(x, y, "hellNoble")
		elseif value == 0xab then
			self:placeMonster(x, y, "hellNoble")
		elseif value == 0xbb then
			self:placeMonster(x, y, "skeleton")
		elseif value == 0xcc then
			self:placeItem(x, y, "flower", "roseWithered")
			self:placeItem(x, y, "flower", "roseWithered")
		elseif value == 0xcd then
			self:placeItem(x, y, "gallows", "wood")
		elseif value == 0xce then
			local _, gallowsEntity = self:placeItem(x, y, "gallows", "wood")
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
					end
				end
				local function onDeactivate(self, item, x, y)
					for _, tile in ipairs(hatches) do
						tile.type = "closedHatch"
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
		elseif value == 0xee then
			self:placeItem(x, y, "huntingShotgun", "steel")
			for _= 1, 16 do
				self:placeItem(x, y, "buckshotShell", "plasticRed")
			end
		elseif value == 0xef then
			self:placeNote(x, y, "TODO: Health kit?")
		elseif value == 0xf0 then
			self:placeNote(x, y, "TODO: Armour?")
		elseif value == 0xf1 then
			self:placeItem(x, y, "rocket", "plasticBlack")
		elseif value == 0xf2 then
			self:placeItem(x, y, "rocketLauncher", "steel")
		elseif value == 0xf3 then
			self:placeNote(x, y, "End of level so far. It's a WIP.")
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
