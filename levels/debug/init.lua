local levelName = (...):gsub("^levels.", "")

local info = {}

-- self is game instance
function info:createLevel()
	-- Various debug situations commented out

	self:initialiseMap(32, 24)
	for x = 0, self.state.map.width - 1 do
		for y = 0, self.state.map.height - 1 do
			-- if x == 0 or x == self.state.map.width - 1 or y == 0 or y == self.state.map.height - 1 then
			-- if self:distance(11, 11, x, y) >= 11 then
			-- 	self:replaceTileInfo(x, y, {type = "wall", material = "marbleGreen"})
			-- else
			-- 	self:replaceTileInfo(x, y, {type = "sand", material = "quartz"})
			-- end

			if
				x == 0 or x == self.state.map.width - 1 or y == 0 or y == self.state.map.height - 1 or
				love.math.random() < 0.1 and false
			then
				self:replaceTileInfo(x, y, {type = "wall", material = "granite"})
			else
				self:replaceTileInfo(x, y, {type = "floor", material = "granite"})
			end
		end
	end

	for x = 0, 5 do
		for y = 6, 10 do
			self:replaceTileInfo(x, y, {type = "wall", material = "granite"})
		end
	end

	-- local monster = self:placeMonster(6, 7, "hellKing")
	-- monster.noAI = true

	for _=1, 20 do
		-- self:placeMonster(20, 20, "zombie")
	end

	-- for x = 9, 15 do
	-- 	for y = 9, 15 do
	-- 		self:replaceTileInfo(x, y, {type = "pit", material = "granite"})
	-- 	end
	-- end
	-- self:replaceTileInfo(12, 12, {type = "wall", material = "granite"})

	-- self:placeItem(1, 1, "tacticalArmour", "hyperPolymer")

	-- self:placeItem(1, 2, "bandage", "cloth")
	-- self:placeItem(2, 2, "bandage", "cloth")
	-- self:placeItem(1, 3, "bandage", "cloth")
	-- self:placeItem(2, 3, "bandage", "cloth")

	-- self:placeItem(4, 2, "smallMedkit", "plasticGreen")
	-- self:placeItem(5, 2, "smallMedkit", "plasticGreen")
	-- self:placeItem(4, 3, "smallMedkit", "plasticGreen")
	-- self:placeItem(5, 3, "smallMedkit", "plasticGreen")

	-- self:placeItem(7, 2, "largeMedkit", "plasticGreen")
	-- self:placeItem(8, 2, "largeMedkit", "plasticGreen")
	-- self:placeItem(7, 3, "largeMedkit", "plasticGreen")
	-- self:placeItem(8, 3, "largeMedkit", "plasticGreen")

	-- self:placeItem(24, 11, "healingRune", "slate")
	-- self:placeItem(11, 2, "healingRune", "slate")
	-- self:placeItem(10, 3, "healingRune", "slate")
	-- self:placeItem(11, 3, "healingRune", "slate")

	-- self:placeItem(7, 7, "rocketLauncher", "polymer")
	-- self:placeItem(7, 7, "rocket", "plasticBrown")

	-- self:placeItem(1, 1, "railgun", "polymer")
	-- local cell = self:placeItem(1, 1, "railgunEnergyCell", "polymer")
	-- cell.storedEnergy = self.state.itemTypes.railgunEnergyCell.maxEnergy

	-- self:placeItem(2, 1, "plasmaShotgun", "polymer")
	-- self:placeItem(3, 1, "plasmaRifle", "polymer")
	-- self:placeItem(4, 1, "plasmathrower", "polymer")
	-- for _=1, 3 do
	-- 	local cell = self:placeItem(3, 0, "plasmaEnergyCell", "polymer")
	-- 	cell.storedEnergy = self.state.itemTypes.plasmaEnergyCell.maxEnergy
	-- end

	-- for x = 4, 10 do
	-- 	for y = 4, 10 do
	-- 		self:getTile(x, y).type = "pit"
	-- 		self:getTile(4, y).type = "wall"
	-- 	end
	-- end

	-- for x = 4, 12 do
	-- 	for y = 4, 12 do
	-- 		if love.math.random() < 0.25 then
	-- 			self.state.map[x][y].type = "wall"
	-- 		end
	-- 	end
	-- end

	-- for _, coord in ipairs({
	-- 	{10, 10},
	-- 	{11, 10},
	-- 	{10, 11},
	-- 	{11, 11}
	-- }) do
	-- 	local person = self:placeCreatureTeam(coord[1], coord[2], "human", "person", "longsword", "steel")
	-- 	person.currentWornItem = self:newItemData({
	-- 		itemTypeName = "knightlyArmour",
	-- 		material = "steel"
	-- 	})
	-- end
	-- self:placeItem(1, 2, "knightlyArmour", "steel")
	-- self:placeItem(2, 1, "longsword", "steel")

	-- local opponent = self:placeMonster(16, 11, "hellNoble")
	-- opponent.inventory[1].item = self:newItemData({
	-- 	itemTypeName = "ornateKey", material = "steel",
	-- 	lockName = "debugKey", breakOnUse = false
	-- })
	-- opponent.inventory.selectedSlot = 1

	-- for _=1, 1 do
	-- 	local monster = self:placeMonster(20, 11, "human", "armArtillery", "steel")
	-- 	local gun = self:getHeldItem(monster)
	-- 	for i = 1, gun.itemType.magazineCapacity do
	-- 		gun.magazineData[i] = self:newItemData({
	-- 			itemTypeName = "experimentalBullet",
	-- 			material = "steel"
	-- 		})
	-- 	end
	-- end
	-- for _=1, 10 do
	-- 	self:placeCreatureTeam(10, 10, "human", "person")
	-- end

	-- self:placeKey(6, 2, "ornateKey", "iron", "debugKey")
	-- self:replaceTileInfo(22, 11, {type = "sand", material = "quartz"})
	-- for x = 23, 25 do
	-- 	for y = 10, 12 do
	-- 		self:replaceTileInfo(x, y, {type = "sand", material = "quartz"})
	-- 	end
	-- end
	-- self:placeDoorItem(22, 11, "ornateDoor", "granite", false, "debugKey")

	return {
		spawnX = 5,
		spawnY = 5,
		postLevelGen = function()
			local player = self.state.player

			-- player.currentWornItem = self:newItemData({itemTypeName = "knightlyArmour", material = "steel"})

			-- player.inventory[1].item = self:newItemData({itemTypeName = "longsword", material = "steel"})
			-- player.inventory.selectedSlot = 1

			-- local shotgun = self:newItemData({itemTypeName = "pumpShotgun", material = "steel"})
			-- shotgun.chamberedRound = self:newItemData({
			-- 	itemTypeName = "buckshotShell",
			-- 	material = "plasticRed"
			-- })
			-- shotgun.cocked = true
			-- local ammoCount = shotgun.itemType.magazineCapacity
			-- for i = 1, ammoCount do
			-- 	shotgun.magazineData[i] = self:newItemData({
			-- 		itemTypeName = "buckshotShell",
			-- 		material = "plasticRed"
			-- 	})
			-- end
			-- player.inventory[1].item = shotgun
			-- player.inventory.selectedSlot = 1

			-- local shotgun = self:newItemData({itemTypeName = "autoShotgun", material = "polymer"})
			-- player.inventory[1].item = shotgun
			-- player.inventory.selectedSlot = 1
			-- player.inventory[2].item = self:newItemData({itemTypeName = "pumpShotgun", material = "polymer"})
			-- player.inventory[3].item = self:newItemData({itemTypeName = "sawnShotgun", material = "steel"})
			-- for _, params in ipairs({
			-- 	{
			-- 		itemTypeName = "buckshotShell",
			-- 		material = "plasticRed"
			-- 	},
			-- 	{
			-- 		itemTypeName = "slugShell",
			-- 		material = "plasticGreen"
			-- 	}
			-- }) do
			-- 	for _= 1, 8 do
			-- 		local item = self:newItemData(params)
			-- 		local slot = self:getBestFreeInventorySlotForItem(player, item)
			-- 		assert(slot and self:addItemToSlot(player, slot, item), "Item was not added to inventory")
			-- 	end
			-- end

			self:placeItem(player.x, player.y, "rocketLauncher", "polymer")
			self:placeItem(player.x, player.y, "rocket", "plasticBrown")
			self:placeItem(player.x, player.y, "rocket", "plasticBrown")

			self:placeItem(player.x + 1, player.y, "grenadeLauncher", "steel")
			self:placeItem(player.x + 1, player.y, "ammoGrenade", "plasticRed")
			self:placeItem(player.x + 1, player.y, "ammoGrenade", "plasticRed")

			self:placeItem(player.x, player.y - 1, "thrownGrenade", "plasticGreen")
			self:placeItem(player.x, player.y - 1, "thrownGrenade", "plasticGreen")
			self:placeItem(player.x, player.y - 1, "thrownGrenade", "plasticGreen")
		end
	}
end

return info
