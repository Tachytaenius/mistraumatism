local game = {}

function game:getTile(x, y)
	local column = self.state.map[x]
	if not column then
		return nil
	end
	return column[y]
end

function game:getWalkable(x, y, ignoreDoors)
	local tile = self:getTile(x, y)
	if not tile then
		return false
	end
	if not ignoreDoors then
		if tile.doorData and not tile.doorData.open then
			return false
		end
	end
	return self.state.tileTypes[tile.type].solidity == "passable"
end

function game:getCheckedNeighbourTiles(x, y, checkFunction) -- Used to, for example, get all walkable neighbour tiles
	local list = {}
	for ox = -1, 1 do
		for oy = -1, 1 do
			if ox == 0 and oy == 0 then
				goto continue
			end
			local tileX, tileY = x + ox, y + oy
			if checkFunction(x, y) then
				list[#list+1] = self:getTile(tileX, tileY)
			end
		    ::continue::
		end
	end
	return list
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

return game
