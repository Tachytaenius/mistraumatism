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

return game
