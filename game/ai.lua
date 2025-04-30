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

local function tryShoot(self, entity)
	local targetEntity = entity.targetEntity
	if not targetEntity then
		return
	end
	if not self:entityCanSeeEntity(entity, targetEntity) then
		return
	end
	return self.state.actionTypes.shoot.construct(self, entity, targetEntity.x, targetEntity.y)
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

	local shootAction = tryShoot(self, entity)
	if shootAction then
		entity.actions[#entity.actions+1] = shootAction
		return
	end

	local moveAction = tryMove(self, entity)
	if moveAction then
		entity.actions[#entity.actions+1] = moveAction
		return
	end
end

return game
