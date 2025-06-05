local pathfind = require("lib.batteries.pathfind")

local consts = require("consts")

local game = {}

-- self is game instance

local function chaseTargetEntity(self, entity)
	local state = self.state

	local targetLocationX, targetLocationY, dontWalkInto
	if entity.targetEntity then
		targetLocationX, targetLocationY = entity.targetEntity.x, entity.targetEntity.y
		dontWalkInto = true
	end

	if targetLocationX and targetLocationY then
		local startTile = self:getTile(entity.x, entity.y)
		local endTile = self:getTile(targetLocationX, targetLocationY)
		if startTile and endTile then
			local function tileHasEntity(tile)
				local list = state.tileEntityLists[tile.x] and state.tileEntityLists[tile.x][tile.y] and state.tileEntityLists[tile.x][tile.y].all
				if list and #list > 0 then
					return true
				end
				return false
			end
			local result = pathfind({
				start = startTile,
				goal = function(tile)
					return tile == endTile
				end,
				neighbours = function(tile)
					return self:getWalkableNeighbourTiles(tile.x, tile.y)
				end,
				distance = function(tileA, tileB)
					local cost = self:distance(tileA.x, tileA.y, tileB.x, tileB.y)
					if tileHasEntity(tileA) or tileHasEntity(tileB) then
						cost = cost * consts.entityPathfindingOccupiedCostMultiplier
					end
					return cost
				end
			})
			if result then
				local nextTile = result[2]
				if nextTile and not (dontWalkInto and nextTile.x == targetLocationX and nextTile.y == targetLocationY) then
					local moveDirection = self:getDirection(nextTile.x - startTile.x, nextTile.y - startTile.y)
					if moveDirection and moveDirection ~= "zero" then
						return self.state.actionTypes.move.construct(self, entity, moveDirection)
					end
				end
			end
		end
	end
end

-- local function tryShootTargetEntity(self, entity)
-- 	local targetEntity = entity.targetEntity
-- 	if not targetEntity then
-- 		return
-- 	end
-- 	if not self:entityCanSeeEntity(entity, targetEntity) then
-- 		return
-- 	end
-- 	return self.state.actionTypes.shoot.construct(self, entity, targetEntity.x, targetEntity.y, targetEntity)
-- end

local function tryMeleeTargetEntity(self, entity)
	local targetEntity = entity.targetEntity
	if not targetEntity then
		return
	end
	local dx, dy = targetEntity.x - entity.x, targetEntity.y - entity.y
	if math.abs(dx) > 1 or math.abs(dy) > 1 then
		return
	end
	local direction = self:getDirection(dx, dy)
	if not direction then
		return
	end
	return self.state.actionTypes.melee.construct(self, entity, targetEntity, direction)
end

function game:getAIActions(entity)
	local state = self.state
	if entity == state.player then
		return
	end
	if entity.dead then
		return
	end

	local newAction

	if entity.targetEntity and self:entityCanSeeEntity(entity, entity.targetEntity) then
		local fightAction
		-- if self:getHeldItem(entity) and self:getHeldItem(entity).itemType.isGun then
		-- 	if self:distance(entity.x, entity.y, entity.targetEntity.x, entity.targetEntity.y) <= self:getHeldItem(entity).itemType.range then
		-- 		fightAction = tryShootTargetEntity(self, entity)
		-- 	end
		-- end
		if not fightAction and entity.creatureType.meleeDamage then
			if math.abs(entity.targetEntity.x - entity.x) <= 1 and math.abs(entity.targetEntity.y - entity.y) <= 1 then -- In range
				fightAction = tryMeleeTargetEntity(self, entity)
			end
		end
		if not fightAction then
			fightAction = chaseTargetEntity(self, entity)
		end

		if fightAction then
			newAction = fightAction
		end
	end

	if newAction then
		entity.actions[#entity.actions+1] = newAction
	end
end

return game
