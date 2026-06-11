-- Not accessible during normal gameplay

local util = require("util")

local levelName = (...):gsub("^levels.", "")

local info = {}

local trees = {
	{value = "elder", weight = 2},
	{value = "oak", weight = 10},
	{value = "appleWood", weight = 6}
}
local leaves = {
	elder = "elderLeaf",
	oak = "oakLeaf",
	appleWood = "appleLeaf"
}
local radii = {
	elder = 1,
	oak = 3,
	appleWood = 2
}

local flowers = {
	{value = "rose", weight = 3},
	{value = "bluebell", weight = 5},
	{value = "borage", weight = 2},
	{value = "foxglove", weight = 1},
	{value = "daisy", weight = 5}
}

local critters = {
	{value = "greySquirrel", weight = 4},
	{value = "redFox", weight = 1},
	{value = "blackbird", weight = 3}
}

-- self is game instance
function info:createLevel() -- name should be the name of the directory containing this file. levels/levelName/init.lua
	local totalW, totalH = 256, 256
	local imageOffsetX, imageOffsetY = 64, 64
	local imageData = love.image.newImageData("levels/" .. levelName .. "/map.png")
	local imageCentreX = imageOffsetX + imageData:getWidth() / 2
	local imageCentreY = imageOffsetY + imageData:getHeight() / 2
	self:initialiseMap(totalW, totalH)

	local types = {
		[0x00] = "fence",
		[0x11] = "grass",
		[0x22] = "brickWall",
		[0x33] = "wall",
		[0x44] = "floor",
		[0x45] = "ornateFloor",
		[0x55] = "glassWindow"
	}
	local materials = {
		[0x00] = "granite",
		[0x11] = "fescue",
		[0x22] = "oak"
	}
	local spawnX, spawnY = math.floor(imageCentreX), math.floor(imageCentreY) -- TEMP
	local function decodeExtra(x, y, r, g, value, a)
		if value == 0x11 then
			self:placeDoorItem(x, y, "door", "oak")
		elseif value == 0x22 then
			self:placeDoorItem(x, y, "ornateDoor", "oak")
		elseif value == 0x23 then
			self:placeDoorItem(x, y, "fenceGate", "oak", true)
		elseif value == 0x24 then
			self:placeItem(x + 1, y, "ornateChair", "oak")
			self:placeItem(x + 2, y, "ornateTable", "oak")
			self:placeItem(x + 3, y, "ornateChair", "oak")
		elseif value == 0x25 then
			self:placeItem(x, y, "toilet", "porcelain")
			self:placeItem(x + 1, y, "bathroomSink", "porcelain")
			self:placeItem(x , y + 1, "bathtub", "porcelain")
		elseif value == 0x26 then

		elseif value == 0x27 then
			
		elseif value == 0x28 then
			self:placeItem(x, y, "bedsideTable", "oak")
			self:placeItem(x + 1, y, "bed", "oak")
		elseif value == 0x33 then
			self:placeCritter(x, y, "greySquirrel")
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

		self:replaceTileInfo(x, y, {
			type = tileType,
			material = tileMaterial
		})
		decodeExtra(x, y, r, g, b, a)
		return r, g, b, a
	end)
	assert(spawnX and spawnY, "No spawn location")

	local seed = 9
	local function noise(x, y)
		return love.math.noise(x + totalW * seed, y + totalH * seed)
	end
	local generator = love.math.newRandomGenerator(seed)
	local placedTrees = {}
	for x = 0, totalW - 1 do
		for y = 0, totalH - 1 do
			local generate = self:getTile(x, y).generate or not (imageOffsetX <= x and x < imageOffsetX + imageData:getWidth() and imageOffsetY <= y and y < imageOffsetY + imageData:getHeight())
			if not generate then
				goto continue
			end
			self:getTile(x, y).generate = nil -- "wasGenerated" gets set
			local type, mat
			local autotileGroup
			mat = "fescue"
			local houseDist = self:distance(x, y, imageCentreX, imageCentreY)
			local radius = math.max(imageData:getDimensions()) / 2
			local woodiness = (1 - math.max(0, noise(x / 30, y / 30) * 0.75 + noise(x / 15, y / 15) * 0.25)) ^ 3
			local forceSapling = houseDist <= radius * 1.4
			local doTree = generator:random() < woodiness / 4
			local sapling, treeMat
			if doTree then
				sapling = generator:random() < 0.08 or forceSapling
				treeMat = util.weightedRandomChoice(trees, generator)
			end
			if doTree and sapling then
				self:placeItem(x, y, "sapling", treeMat)
			end
			if doTree and not sapling then
				type = "treeTrunk"
				mat = treeMat
				autotileGroup = self:getAutotileGroupId()
				table.insert(placedTrees, {x = x, y = y, type = treeMat})
			else
				local length = (
					noise(x / 15, y / 15) * 0.5 +
					noise(x / 6, y / 6) * 0.25 +
					noise(x / 3, y / 3) * 0.125 +
					generator:random() * 0.125
				) * (1 - woodiness)
				type = length < 1/4 and "softEarth" or length < 2/4 and "shortGrass" or length < 3/4 and "grass" or "longGrass"
				if type == "softEarth" then
					mat = "soilLoamy"
				end

				if not sapling then
					local flowerChance = (1 - woodiness) ^ 10 * 0.1
					if generator:random() < flowerChance then
						self:placeItem(x, y, "flower", util.weightedRandomChoice(flowers, generator))
					end
				end

				local critterChance = 0.0025
				if generator:random() < critterChance then
					self:placeCritter(x, y, util.weightedRandomChoice(critters, generator))
				end
			end
			self:replaceTileInfo(x, y, {
				type = type,
				material = mat,
				autotileGroup = autotileGroup,
				wasGenerated = true
			})
			::continue::
		end
	end

	-- Place leaf litter spatter
	for _, tree in ipairs(placedTrees) do
		local radius = radii[tree.type]
		for ox = -radius, radius do
			for oy = -radius, radius do
				local x = tree.x + ox
				local y = tree.y + oy
				-- I don't know why but artistically I feel like I want to use the manhattan distance to get a diamond shape
				local dist = math.abs(ox) + math.abs(oy)
				local amount = math.max(0, radius - dist + 1)
				-- local mul = generator:random() ^ 2.5 * 5
				local mul = generator:random(0, 1)
				amount = math.floor(amount * mul)
				local tile = self:getTile(x, y)
				if tile and tile.wasGenerated and not self:tileBlocksAirMotion(x, y) then
					self:addSpatter(x, y, leaves[tree.type], amount)
				end
			end
		end
	end

	return {
		spawnX = spawnX,
		spawnY = spawnY,
		postLevelGen = function()
			self:setReachedSafety()
		end
	}
end

return info
