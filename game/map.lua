local game = {}

function game:getTile(x, y)
	local column = self.state.map[x]
	if not column then
		return nil
	end
	return column[y]
end

function game:getWalkable(x, y, ignoreDoors, canFly)
	local tile = self:getTile(x, y)
	if not tile then
		return false
	end
	if not ignoreDoors then
		if tile.doorData and not tile.doorData.open then
			return false
		end
	end
	local solidity = self.state.tileTypes[tile.type].solidity
	return solidity == "passable" or canFly and solidity == "fall"
end

function game:getCheckedNeighbourTiles(x, y, checkFunction, includeCentreTile) -- Used to, for example, get all walkable neighbour tiles
	local list = {}
	for ox = -1, 1 do
		for oy = -1, 1 do
			if ox == 0 and oy == 0 and not includeCentreTile then
				goto continue
			end
			local tileX, tileY = x + ox, y + oy
			if checkFunction(tileX, tileY) then
				list[#list+1] = self:getTile(tileX, tileY)
			end
		    ::continue::
		end
	end
	return list
end

function game:removeSpatter(x, y, materialName, amount) -- Returns amount removed
	if amount == 0 then
		return 0
	end
	local tile = self:getTile(x, y)
	if not tile then
		return 0
	end
	if not tile.spatter then
		return 0
	end
	for i, tileSpatter in ipairs(tile.spatter) do
		if tileSpatter.materialName == materialName then
			-- if amount == "all" then -- Just use math.huge
			local amountToRemove = math.min(tileSpatter.amount, amount)
			tileSpatter.amount = tileSpatter.amount - amountToRemove
			if tileSpatter.amount <= 0 then
				table.remove(tile.spatter, i)
				if #tile.spatter == 0 then
					tile.spatter = nil
					self.state.map.spatteredTiles[tile] = nil
				end
			end
			return amountToRemove
		end
	end
	return 0
end

function game:deleteAllSpatter(x, y) -- No return value
	local tile = self:getTile(x, y)
	if not tile then
		return
	end
	tile.spatter = nil
	self.state.map.spatteredTiles[tile] = nil
end

function game:deleteAllLiquidSpatter(x, y) -- No return value
	local tile = self:getTile(x, y)
	if not tile or not tile.spatter then
		return
	end
	local i = 1
	while tile.spatter and i <= #tile.spatter do
		local spatter = tile.spatter[i]
		if self.state.materials[spatter.materialName].matterState == "liquid" then
			self:removeSpatter(x, y, spatter.materialName, math.huge)
		else
			i = i + 1
		end
	end
end

function game:addSpatter(x, y, materialName, amount)
	if amount == 0 then
		return
	end
	local tile = self:getTile(x, y)
	if not tile then
		return
	end
	if not tile.spatter then
		tile.spatter = {}
		self.state.map.spatteredTiles[tile] = true
	end
	local spatter
	for _, tileSpatter in ipairs(tile.spatter) do
		if tileSpatter.materialName == materialName then
			spatter = tileSpatter
			break
		end
	end
	if not spatter then
		tile.spatter[#tile.spatter + 1] = {
			materialName = materialName,
			amount = amount
		}
	else
		spatter.amount = spatter.amount + amount
	end
end

function game:dropSpatters()
	for tile in pairs(self.state.map.spatteredTiles) do
		local deleteType = self.state.tileTypes[tile.type].deleteSpatter
		if deleteType == "all" then
			self:deleteAllSpatter(tile.x, tile.y)
		elseif deleteType == "liquid" then
			self:deleteAllLiquidSpatter(tile.x, tile.y)
		end
	end
end

return game
