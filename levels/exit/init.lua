local levelName = (...):gsub("^levels.", "")

local info = {}

-- self is game instance
function info:createLevel() -- name should be the name of the directory containing this file. levels/levelName/init.lua
	local imageData = love.image.newImageData("levels/" .. levelName .. "/map.png")
	self:initialiseMap(imageData:getDimensions())

	local generator = love.math.newRandomGenerator(2)

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
		[0xcc] = "fullGlassWindow",
		[0xff] = "archway"
	}
	local materials = {
		[0x00] = "granite",
		[0x11] = "obsidian",
		[0x55] = "ornateCarpet",
		[0xaa] = "fescue",
		[0xbb] = "bloodRed",
		[0xff] = "glass"
	}
	local spawnX, spawnY
	local ceilingMessage = self:newTileMessage("There is a skyward hole in the cavern ceiling above\nyou. The sunlight sifts down and glints at you\nagainst the dust.", "white")
	local exitDoorX, exitDoorY
	local function decodeExtra(x, y, r, g, value, a)
		-- NOTE: There are intentionally no healing items in this level!!
		-- So that if you're bleeding out the game just doesn't let you escape. Less cases to deal with, so it's easier

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
			self:placeKey(x, y, "ornateKey", "bone", "exitArena1")
		elseif value == 0x5b then
			self:placeDoorItem(x, y, "ornateDoor", "granite", false, "exitArena1")
		elseif value == 0x5c then
			self:placeDoorItem(x, y, "ornateDoor", "granite", false)
		elseif value == 0x5d then

			local seal = self:placeExaminable(x, y, "exitSeal", "inflictionMagic", "Malice still clings to this door. It is sealed.")
			seal.isExitSeal = true

			self:placeDoorItem(x, y, "heavyDoor", "obsidian", false, "noKey")
			exitDoorX, exitDoorY = x, y
			self:getTile(x, y).isGameFinishTrigger = true
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
			-- self:placeItem(x, y, "largeMedkit", "plasticGreen")
		elseif value == 0xe3 then
			self:placeItem(x, y, "tacticalArmour", "hyperPolymer")
			self:placeItem(x - 1, y, "combatKnife", "steel")
		elseif value == 0xe4 then
			self:placeItem(x, y, "rocketLauncher", "polymer")
		elseif value == 0xe5 then
			for _=1, 2 do
				self:placeItem(x, y, "rocket", "plasticBrown")
			end
		elseif value == 0xe6 then
			self:placeItem(x, y, "autoShotgun", "polymer")
		elseif value == 0xe7 then
			for _=1, 8 do
				self:placeItem(x, y, "buckshotShell", "plasticRed")
			end
		elseif value == 0xe8 then
			-- self:placeItem(x, y, "smallMedkit", "plasticGreen")
		elseif value == 0xe9 then
			self:placeItem(x, y, "pistol", "polymer")
		elseif value == 0xea then
			self:placeMagazineWithAmmo(x, y, "pistolMagazine", "polymer", "smallBullet", "brass")
		elseif value == 0xeb then
			for _=1, 8 do
				self:placeItem(x, y, "slugShell", "plasticGreen")
			end
		elseif value == 0xec then
			self:placeItem(x, y, "altar", "granite")
		elseif value == 0xfe then
			self:addSpatter(x, y, "glass", generator:random(1, 7))
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

	local function openExit()
		self:mechanismOpenDoor(exitDoorX, exitDoorY)
		local particleCount = 80
		local rand = 9
		local choices = {
			-- "red", "yellow", "green", "cyan", "blue", "magenta"
			-- "cyan", "magenta", "white"
			"red", "cyan"
		}
		local tileChoices = {
			-- "·", "'", "`", "."
			"·"
		}
		local lifetimeMin = 2
		local lifetimeMax = 20
		local slownessMin, slownessMax = 128, 1024
		self:tickItems(function(item, x, y, locationType, locationEntity)
			if item.isExitSeal then
				for _=1, particleCount do
					self:newParticle({}, {
						startX = x,
						startY = y,
						targetX = x + love.math.random(-rand, rand),
						targetY = y + love.math.random(-rand, rand),

						foregroundColour = choices[love.math.random(#choices)],
						backgroundColour = "black",

						tile = tileChoices[love.math.random(#tileChoices)],

						lifetime = love.math.random(lifetimeMin, lifetimeMax),

						subtickMoveTimerLength = love.math.random(slownessMin, slownessMax)
					})
				end
				return true
			end
		end)
	end

	function self.state.allMonstersDeadFunc()
		if not self.state.player or self.state.player.dead then
			return
		end
		self:fadeMusicOut(5)
		local bleedingOut, willLoseBlood = self:isEntityBleedingOut(self.state.player)
		if bleedingOut then
			self:announce("Something is different, but you can't know what.", "white")
		else
			self:announce("Something feels different...", "white")
			openExit()
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
			self.state.horrifiedMusicDone = false
			self.state.horrifiedMusicName = "nail-and-claw"
			self.horrorMusicFadeInTimerLength = 0
			-- self:setMusic("nail-and-claw")
		end
	}
end

return info
