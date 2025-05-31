local game = {}

function game:loadTileTypes()
	local state = self.state
	state.tileTypes = {
		wall = {
			displayName = "wall",
			solidity = "solid",
			character = "O",
			boxDrawingNumber = 2,
			blocksLight = true
		},
		floor = {
			displayName = "floor",
			solidity = "passable",
			character = "+"
		},
		pit = {
			displayName = "pit",
			solidity = "fall",
			character = "∙",
			ignoreSpatter = true,
			darkenColour = true
		}
	}
end

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

function game:getWalkableNeighbourTiles(x, y)
	local list = {}
	for ox = -1, 1 do
		for oy = -1, 1 do
			if ox == 0 and oy == 0 then
				goto continue
			end
			local tileX, tileY = x + ox, y + oy
			if self:getWalkable(tileX, tileY) then
				list[#list+1] = self:getTile(tileX, tileY)
			end
		    ::continue::
		end
	end
	return list
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
