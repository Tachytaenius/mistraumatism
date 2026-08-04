local util = require("util")

local levelName = (...):gsub("^levels.", "")

local info = {}

-- self is game instance
function info:createLevel() -- name should be the name of the directory containing this file. levels/levelName/init.lua
	local totalW, totalH = 256, 256
	local imageCentreX = math.floor(totalW / 2)
	local imageCentreY = math.floor(totalH / 2)
	local imageData = love.image.newImageData("levels/" .. levelName .. "/map.png")
	local imageOffsetX = imageCentreX - math.floor(imageData:getWidth() / 2)
	local imageOffsetY = imageCentreY - math.floor(imageData:getHeight() / 2)
	self:initialiseMap(totalW, totalH)

	local types = {
		[0x00] = "wall",
		[0x11] = "floor",
		[0x22] = "pit" -- All pits are filled up when the hell king dies-- we don't want the hell king's key to drop into one!
	}
	local materials = {
		[0x00] = "basalt",
		[0x11] = "inflictionMagic"
	}
	local spawnX, spawnY = math.floor(imageCentreX), math.floor(imageCentreY)
	local pathEndX, pathEndY
	local function decodeExtra(x, y, r, g, value, a)
		if value == 0x11 then
			self:placeDoorItem(x, y, "heavyDoor", "granite", false, "noKey")
			self:placeDoorItem(x - 1, y, "heavyDoor", "granite", false, "noKey")
			local function onActivate(self, item, leverX, leverY)
				self:mechanismOpenDoor(x, y)
				self:mechanismOpenDoor(x - 1, y)
			end
			local function onDeactivate(self, item, leverX, leverY)
				self:mechanismShutDoor(x, y)
				self:mechanismShutDoor(x - 1, y)
			end
			self:placeLever(x + 1, y + 1, "steel", false, onActivate, onDeactivate)
		elseif value == 0x12 then
			self:placeDoorItem(x, y, "ornateDoor", "granite", false)
		elseif value == 0x22 then
			self:placeItem(x, y, "rocketLauncher", "polymer")
			for _=1, 6 do
				self:placeItem(x, y, "rocket", "plasticBrown")
			end

			-- self:placeItem(x + 1, y, "pistol", "steel")
			-- self:placeMagazineWithAmmo(x + 1, y, "pistolMagazine", "steel", "smallBullet", "brass")
			self:placeItem(x + 1, y, "revolverDoubleAction", "steel")
			for _=1, 12 do
				self:placeItem(x + 1, y, "mediumBullet", "brass")
			end
			-- self:placeItem(x + 1, y, "revolverSingleAction", "steel")
			-- for _=1, 16 do
			-- 	self:placeItem(x + 1, y, "smallBullet", "brass")
			-- end

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
			local opponent = self:placeMonster(x, y, "hellKing")
			opponent.inventory[1].item = self:newItemData({
				itemTypeName = "ornateKey", material = "gold",
				lockName = "leavePatriarchalCesspoolLevel", breakOnUse = true
			})
			opponent.inventory[2].item = self:newItemData({
				itemTypeName = "phallicSceptre", material = "gold"
			})
			opponent.inventory.selectedSlot = 2
			opponent.currentWornItem = self:newItemData({
				itemTypeName = "cruelMitre", material = "gold"
			})
			opponent.onKill = function(self, entity)
				for x = 0, self.state.map.width - 1 do
					for y = 0, self.state.map.width - 1 do
						local tile = self:getTile(x, y)
						if tile.type == "pit" and not tile.fallLevelChange then
							tile.type = "frozenFloor"
							tile.material = "bloodRed"
						end
					end
				end
			end
			opponent.seePlayerMusic = "primordial-sickness"
			opponent.seePlayerMusicForceFadeStop = true
			opponent.seePlayerMusicFadeOutLength = 6
		elseif value == 0x44 then
			pathEndX = x
			pathEndY = y
		elseif value == 0x55 then
			self:placeDoorItem(x, y, "ornateDoor", "granite", false, "leavePatriarchalCesspoolLevel")
		elseif value == 0x66 then
			local tile = self:getTile(x, y)
			tile.fallLevelChange = "underwaterMaze"
			tile.type = "floorPortal1"
			tile.material = "water"
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

			local dist = self:distance(x, y, imageCentreX, imageCentreY)
			local max = math.min(totalW, totalH) / 2
			if dist > max * 0.95 then
				type = "roughWall"
				mat = "basalt"
			elseif dist > max * 0.93 then
				type = "roughFloor"
				mat = "basalt"
			end
			local blood = math.max(0, math.floor(6 * (dist / (max * 0.95)) ^ 4.5 * love.math.noise(x / 2, y / 2)))
			local flesh = math.max(0, math.floor(3 * (dist / (max * 0.95)) ^ 9.5 * love.math.noise(x / 6, y / 6)))
			self:addSpatter(x, y, "bloodRed", blood)
			if type == "frozenFloor" or type == "roughFloor" then
				self:addSpatter(x, y, "fleshRed", flesh)
				local corpseChance = (dist / (max * 0.95)) ^ 12 / 8
				if generator:random() < corpseChance then
					-- Fell off the basalt wall into the frozen centre circle of Hell
					local corpse = self:placeCorpseTeam(x, y, "human", "person")
					corpse.health = -math.floor(generator:random() * 1.8 * self.state.creatureTypes.human.maxHealth + 0.5)
					corpse.blood = 0
				end
			end

			tile.material = mat
			tile.type = type

			if type == "frozenFloor" or type == "roughFloor" then
				local snowiness = love.math.noise(x / 10, y / 10) ^ 2
				self:addSpatter(x, y, "snow", math.floor(snowiness * 10))
			end

			::continue::
		end
	end

	for y = pathEndY + 1, pathEndY + 1 + 34 do
		local w = 2
		for xo = -w, w+1 do
			local x = pathEndX + xo
			if not self:tileBlocksAirMotion(x, y) then
				local offCentre = math.min(math.abs(xo), math.abs(xo - 1)) / w
				-- self:addSpatter(x, y, "bloodRed", math.floor((1 - offCentre + 0.5) * love.math.random(5, 16)))
				-- self:addSpatter(x, y, "fleshRed", love.math.random(0, offCentre * 24))
				local amount = math.floor((1 - offCentre + 0.5) * generator:random(1, 24))
				self:addSpatter(x, y, "salt", amount)
				self:removeSpatter(x, y, "snow", amount * 3)
			end
		end
	end

	return {
		spawnX = spawnX,
		spawnY = spawnY,
		postLevelGen = function()
			if self.music then
				-- Fade out any horrified music
				self:fadeMusicOut(2)
			end
		end
	}
end

return info
