local levelName = (...):gsub("^levels.", "")

local info = {}

-- self is game instance
function info:createLevel()
	self:initialiseMap(16, 16)
	for x = 0, self.state.map.width - 1 do
		for y = 0, self.state.map.height - 1 do
			self:replaceTileInfo(x, y, {type = "roughFloor", material = "granite"})
		end
	end

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

	-- self:placeItem(10, 2, "healingRune", "slate")
	-- self:placeItem(11, 2, "healingRune", "slate")
	-- self:placeItem(10, 3, "healingRune", "slate")
	-- self:placeItem(11, 3, "healingRune", "slate")

	self:placeItem(1, 0, "rocketLauncher", "polymer")
	self:placeItem(1, 0, "rocket", "plasticBrown")

	self:placeItem(1, 1, "railgun", "polymer")
	local cell = self:placeItem(1, 1, "railgunEnergyCell", "polymer")
	cell.storedEnergy = self.state.itemTypes.railgunEnergyCell.maxEnergy

	self:placeItem(2, 1, "plasmaShotgun", "polymer")
	self:placeItem(3, 1, "plasmaRifle", "polymer")
	self:placeItem(4, 1, "plasmathrower", "polymer")
	for _=1, 3 do
		local cell = self:placeItem(3, 0, "plasmaEnergyCell", "polymer")
		cell.storedEnergy = self.state.itemTypes.plasmaEnergyCell.maxEnergy
	end

	for x = 4, 12 do
		for y = 4, 12 do
			if love.math.random() < 0.25 then
				self.state.map[x][y].type = "wall"
			end
		end
	end

	-- self:placeMonster(14, 14, "demonicPriest")

	return {
		spawnX = 0,
		spawnY = 0,
		-- playerHealth = 1,
		-- playerBleedRate = 40
	}
end

return info
