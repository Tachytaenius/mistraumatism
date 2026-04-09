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

	local seed = 0
	local function noise(x, y)
		return love.math.noise(x + totalW * seed, y + totalH * seed)
	end
	local generator = love.math.newRandomGenerator(seed)
	for x = 0, totalW - 1 do
		for y = 0, totalH - 1 do
			local generate = self:getTile(x, y).generate or not (imageOffsetX <= x and x < imageOffsetX + imageData:getWidth() and imageOffsetY <= y and y < imageOffsetY + imageData:getHeight())
			if not generate then
				goto continue
			end
			self:getTile(x, y).generate = nil
			local type, mat
			local autotileGroup
			mat = "fescue"
			local woodiness = (1 - math.max(0, noise(x / 30, y / 30) * 0.75 + noise(x / 15, y / 15) * 0.25)) ^ 3
			local doTree = generator:random() < woodiness / 4
			local sapling, treeMat
			if doTree then
				sapling = generator:random() < 0.08
				treeMat = util.weightedRandomChoice(trees, generator)
			end
			if doTree and sapling then
				self:placeItem(x, y, "sapling", treeMat)
			end
			if doTree and not sapling then
				type = "treeTrunk"
				mat = treeMat
				autotileGroup = self:getAutotileGroupId()
			else
				local length = (
					noise(x / 15, y / 15) * 0.5 +
					noise(x / 6, y / 6) * 0.25 +
					noise(x / 3, y / 3) * 0.125 +
					generator:random() * 0.125
				) * (1 - woodiness)
				type = length < 1/4 and "softEarth" or length < 2/4 and "shortGrass" or length < 3/4 and "grass" or "longGrass"
				if type == "softEarth" then
					local leafiness = math.max(0, woodiness - 0.2) / 0.8
					if generator:random() < leafiness then
						type = "leafLitter"
						mat = leaves[util.weightedRandomChoice(trees, generator)]
					else
						mat = "soilLoamy"
					end
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
				autotileGroup = autotileGroup
			})
			::continue::
		end
	end

	return {
		spawnX = spawnX,
		spawnY = spawnY
	}
end

return info
