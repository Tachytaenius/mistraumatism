local game = {}

function game:getTile(x, y)
	local column = self.state.map[x]
	if not column then
		return nil
	end
	return column[y]
end

function game:getWalkable(x, y)
	local tile = self:getTile(x, y)
	return tile and self.state.tileTypes[tile.type].solidity == "passable"
end

function game:addSpatter(x, y, materialName, amount)
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
