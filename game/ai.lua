local pathfind = require("lib.batteries.pathfind")

local game = {}

-- self is game instance
local function tryMove(self, entity)
	local targetLocationX, targetLocationY
	if entity.targetEntity then
		targetLocationX, targetLocationY = entity.targetEntity.x, entity.targetEntity.y
	end

	if targetLocationX and targetLocationY then
		local startTile = self:getTile(entity.x, entity.y)
		local endTile = self:getTile(targetLocationX, targetLocationY)
		if startTile and endTile then
			local result = pathfind({
				start = startTile,
				goal = function(tile)
					return tile == endTile
				end,
				neighbours = function(tile)
					return self:getWalkableNeighbourTiles(tile.x, tile.y)
				end,
				distance = function(tileA, tileB)
					return math.sqrt(
						(tileB.x - tileA.x) ^ 2 +
						(tileB.y - tileA.y) ^ 2
					)
				end
			})
			if result then
				local nextTile = result[2]
				if nextTile then
					local moveDirection = self:getDirection(nextTile.x - startTile.x, nextTile.y - startTile.y)
					if moveDirection then
						return self.state.actionTypes.move.construct(self, entity, moveDirection)
					end
				end
			end
		end
	end
end

function game:getAIActions(entity)
	local state = self.state
	if entity == state.player then
		return
	end
	if entity.dead then
		return
	end

	-- Return after every potential action

	local moveAction = tryMove(self, entity)
	if moveAction then
		entity.actions[#entity.actions+1] = moveAction
		return
	end
end

return game
