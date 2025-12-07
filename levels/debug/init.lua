local levelName = (...):gsub("^levels.", "")

local info = {}

-- self is game instance
function info:createLevel()
	self:initialiseMap(32, 24)
	for x = 0, self.state.map.width - 1 do
		for y = 0, self.state.map.height - 1 do
			-- if x == 0 or x == self.state.map.width - 1 or y == 0 or y == self.state.map.height - 1 then
			if self:distance(11, 11, x, y) >= 11 then
				self:replaceTileInfo(x, y, {type = "wall", material = "marbleGreen"})
			else
				self:replaceTileInfo(x, y, {type = "sand", material = "quartz"})
			end
		end
	end

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

	self:placeItem(24, 11, "healingRune", "slate")
	-- self:placeItem(11, 2, "healingRune", "slate")
	-- self:placeItem(10, 3, "healingRune", "slate")
	-- self:placeItem(11, 3, "healingRune", "slate")

	self:placeItem(7, 7, "rocketLauncher", "polymer")
	self:placeItem(7, 7, "rocket", "plasticBrown")

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

	local opponent = self:placeMonster(16, 11, "hellNoble")
	opponent.inventory[1].item = self:newItemData({
		itemTypeName = "ornateKey", material = "steel",
		lockName = "debugKey", breakOnUse = false
	})
	opponent.inventory.selectedSlot = 1

	-- self:placeKey(6, 2, "ornateKey", "iron", "debugKey")
	self:replaceTileInfo(22, 11, {type = "sand", material = "quartz"})
	for x = 23, 25 do
		for y = 10, 12 do
			self:replaceTileInfo(x, y, {type = "sand", material = "quartz"})
		end
	end
	self:placeDoorItem(22, 11, "ornateDoor", "granite", false, "debugKey")

	return {
		spawnX = 7,
		spawnY = 11,
		postLevelGen = function()
			local player = self.state.player

			player.currentWornItem = self:newItemData({itemTypeName = "knightlyArmour", material = "steel"})

			player.inventory[1].item = self:newItemData({itemTypeName = "longsword", material = "steel"})
			player.inventory.selectedSlot = 1
		end
	}
end

return info
