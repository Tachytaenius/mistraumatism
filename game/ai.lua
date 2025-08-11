local pathfind = require("lib.batteries.pathfind")

local consts = require("consts")

local game = {}

-- self is game instance

local function tilePathCheckFunction(self, tileX, tileY, entity)
	local tile = self:getTile(tileX, tileY)
	if not tile then
		return false
	end
	if tile.doorData then
		if not tile.doorData.open and not (entity.creatureType.canOpenDoors and tile.doorData.entity.itemData.itemType.interactable) then
			return false
		end
	end
	return self:getWalkable(tileX, tileY, true, entity.creatureType.flying)
end

local function chase(self, entity, sameTileMelee)
	local state = self.state

	local targetLocationX, targetLocationY, dontWalkInto
	local onlyGoingToLastKnownLocation
	local investigating
	if entity.targetEntity then
		if self:entityCanSeeEntity(entity, entity.targetEntity) then
			targetLocationX, targetLocationY = entity.targetEntity.x, entity.targetEntity.y
			dontWalkInto = not sameTileMelee
		elseif entity.lastKnownTargetLocation then
			onlyGoingToLastKnownLocation = true
			targetLocationX, targetLocationY = entity.lastKnownTargetLocation.x, entity.lastKnownTargetLocation.y
		end
	end
	if entity.investigateLocation and (not entity.targetEntity or onlyGoingToLastKnownLocation) then
		investigating = true
		if entity.investigateLocation.eventData and state.eventTypes[entity.investigateLocation.eventData.type].investigateLocationOverride then
			local overrideLocation = entity.investigateLocation.eventData[state.eventTypes[entity.investigateLocation.eventData.type].investigateLocationOverride]
			targetLocationX, targetLocationY = overrideLocation.x, overrideLocation.y
		else
			targetLocationX, targetLocationY = entity.investigateLocation.x, entity.investigateLocation.y
		end
	end

	if targetLocationX and targetLocationY then
		local startTile = self:getTile(entity.x, entity.y)
		local endTile = self:getTile(targetLocationX, targetLocationY)
		if startTile and endTile then
			local function tileHasEntityToAvoid(tile, excludeEntity)
				local list = state.tileEntityLists[tile.x] and state.tileEntityLists[tile.x][tile.y] and state.tileEntityLists[tile.x][tile.y].all
				if list then
					for _, entity in ipairs(list) do
						if entity.entityType == "creature" and not entity.dead and entity ~= excludeEntity then
							return true
						end
					end
				end
				return false
			end
			local function checkFunction(tileX, tileY)
				return tilePathCheckFunction(self, tileX, tileY, entity)
			end
			local result = pathfind({
				start = startTile,
				goal = function(tile)
					return tile == endTile
				end,
				neighbours = function(tile)
					return self:getCheckedNeighbourTiles(tile.x, tile.y, checkFunction)
				end,
				distance = function(tileA, tileB)
					local cost = self:distance(tileA.x, tileA.y, tileB.x, tileB.y)
					if tileHasEntityToAvoid(tileA, entity) or tileHasEntityToAvoid(tileB, entity) then
						cost = cost * consts.entityPathfindingOccupiedCostMultiplier
					end
					return cost
				end
			})
			if result then
				local nextTile = result[2]
				if nextTile and not (dontWalkInto and nextTile.x == targetLocationX and nextTile.y == targetLocationY) then
					local direction = self:getDirection(nextTile.x - startTile.x, nextTile.y - startTile.y)
					if direction then
						local keepInvestigation = true
						if nextTile.doorData and not nextTile.doorData.open then
							return self.state.actionTypes.interact.construct(self, entity, nextTile.doorData.entity, direction)
						elseif direction ~= "zero" then
							return self.state.actionTypes.move.construct(self, entity, direction)
						else
							keepInvestigation = false
						end
						if investigating and keepInvestigation then
							entity.investigateLocation.timeoutTimer = 0
						end
					end
				end
				if investigating and not nextTile then
					entity.investigateLocation = nil
				end
			end
		end
	end
end

local function fleeLastKnownFleeFromEntityPositions(self, entity)
	-- Lots of complexity that didn't really end up doing what I wanted.

	local state = self.state

	-- Get walkable neighbours
	local function checkFunction(tileX, tileY)
		return tilePathCheckFunction(self, tileX, tileY, entity)
	end
	local potentialNextSteps = self:getCheckedNeighbourTiles(entity.x, entity.y, checkFunction, true)

	-- Get closest flee from entity
	local closestFleeFromInfo
	local closestFleeFromDistance = math.huge
	for _, fleeEntityInfo in ipairs(entity.fleeFromEntities) do
		local distance = self:distance(entity.x, entity.y, fleeEntityInfo.lastKnownX, fleeEntityInfo.lastKnownY)
		if distance < closestFleeFromDistance then
			closestFleeFromInfo = fleeEntityInfo
			closestFleeFromDistance = distance
		end
	end

	-- Get tile which is most aligned with the direction away from closest flee from entity

	local nextTile
	if closestFleeFromDistance == 0 then
		nextTile = potentialNextSteps[love.math.random(#potentialNextSteps)]
	else
		if not closestFleeFromInfo then
			return
		end
		local fleeX, fleeY = entity.x - closestFleeFromInfo.lastKnownX, entity.y - closestFleeFromInfo.lastKnownY
		local fleeDirX, fleeDirY = fleeX / closestFleeFromDistance, fleeY / closestFleeFromDistance

		local function getScore(x, y)
			local stepX, stepY = x - entity.x, y - entity.y
			local stepDist = self:length(stepX, stepY)
			if stepDist == 0 then
				return -math.huge
			end
			local stepDirX, stepDirY = stepX / stepDist, stepY / stepDist
			if self:distance(x, y, closestFleeFromInfo.lastKnownX, closestFleeFromInfo.lastKnownY) < closestFleeFromDistance then
				return nil -- Exclude from checks
			end
			local dot = stepDirX * fleeDirX + stepDirY * fleeDirY -- Dot product of normalised vectors :)
			return dot >= 0 and dot or nil
		end

		local highestScore = -math.huge
		local scores = {}
		for _, tile in ipairs(potentialNextSteps) do
			local tileScore = getScore(tile.x, tile.y)
			if not tileScore then
				goto continue
			end
			scores[tile] = tileScore
			highestScore = math.max(highestScore, tileScore)
		    ::continue::
		end

		local choices = {}
		for _, tile in ipairs(potentialNextSteps) do
			if scores[tile] and scores[tile] >= highestScore then
				choices[#choices+1] = tile
			end
		end

		nextTile = choices[love.math.random(#choices)]

		if not nextTile then
			-- Find tile that takes entity furthest from what it's fleeing from
			local furthestTile
			local furthestTileDistance = -math.huge
			for _, tile in ipairs(potentialNextSteps) do
				local dist = self:distance(tile.x, tile.y, closestFleeFromInfo.lastKnownX, closestFleeFromInfo.lastKnownY)
				if furthestTileDistance < dist then
					furthestTileDistance = dist
					furthestTile = tile
				end
			end
			nextTile = furthestTile
		end
	end

	if nextTile then
		local direction = self:getDirection(nextTile.x - entity.x, nextTile.y - entity.y)
		if direction then
			if nextTile.doorData and not nextTile.doorData.open then
				return self.state.actionTypes.interact.construct(self, entity, nextTile.doorData.entity, direction)
			elseif direction ~= "zero" then
				return self.state.actionTypes.move.construct(self, entity, direction)
			end
		end
	end
end

local function tryShootTargetEntity(self, entity, shotType, abilityName)
	local targetEntity = entity.targetEntity
	if not targetEntity then
		return
	end
	if not (self:entityCanSeeEntity(entity, targetEntity) and self:projectileCanPathFromEntityToEntity(entity, targetEntity)) then
		return
	end
	return self.state.actionTypes.shoot.construct(self, entity, targetEntity.x, targetEntity.y, targetEntity, shotType, abilityName)
end

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
	local charge = direction ~= "zero" and entity.creatureType.chargeMelee and not entity.targetEntity.dead
	return self.state.actionTypes.melee.construct(self, entity, targetEntity, direction, charge)
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
	local waitForSameTileMelee

	if entity.fleeFromEntities and #entity.fleeFromEntities > 0 then
		newAction = fleeLastKnownFleeFromEntityPositions(self, entity)
	elseif entity.targetEntity then
		local canSee = self:entityCanSeeEntity(entity, entity.targetEntity)
		local fightAction
		if canSee then
			local shootType = self:getHeldItem(entity) and self:getHeldItem(entity).itemType.isGun and "gun" or entity.creatureType.projectileAbilities and #entity.creatureType.projectileAbilities > 0 and "ability" or nil
			-- Don't shoot if the entity is dead (we'd only be here if entity.creatureType.attackDeadTargets is true, and its purpose is to make monsters destroy corpses, which seems better suited for melee)
			if entity.targetEntity.dead then
				shootType = nil
			end
			-- Random chance (per tick) to not choose to shoot
			if love.math.random() >= (entity.creatureType.shootAggressiveness or 1) then
				shootType = nil
			end
			if shootType then
				local range
				local distance = self:distance(entity.x, entity.y, entity.targetEntity.x, entity.targetEntity.y)
				if shootType == "gun" then
					range = self:getHeldItem(entity).itemType.range
					if distance <= range then
						fightAction = tryShootTargetEntity(self, entity, "heldItem")
					end
				elseif shootType == "ability" then
					local choosableAbilities = {}
					for _, ability in ipairs(entity.creatureType.projectileAbilities) do
						if distance <= ability.range then
							choosableAbilities[#choosableAbilities+1] = ability
						end
					end
					if #choosableAbilities > 0 then
						local chosenAbility = choosableAbilities[love.math.random(#choosableAbilities)]
						fightAction = tryShootTargetEntity(self, entity, "ability", chosenAbility.name)
					end
				end
			end
			if not fightAction and entity.creatureType.meleeDamage then
				if math.abs(entity.targetEntity.x - entity.x) <= 1 and math.abs(entity.targetEntity.y - entity.y) <= 1 then -- In range
					-- if not (entity.x == entity.targetEntity.x and entity.y == entity.targetEntity.y) then
					-- 	waitForSameTileMelee = true
					-- else
						fightAction = tryMeleeTargetEntity(self, entity)
					-- end
				end
			end
		end

		if fightAction then
			newAction = fightAction
		end
	end

	if not newAction then
		newAction = chase(self, entity, waitForSameTileMelee)
	end

	if newAction then
		entity.actions[#entity.actions+1] = newAction
	end
end

function game:getEventImportance(entity, eventData)
	if not eventData.sourceEntity then
		-- Nobody to investigate
		return 0
	end
	if self:getTeamRelation(entity.team, eventData.sourceEntity.team) ~= "friendly" then
		-- Investigate anything from non-friendly teams
		if self.state.eventTypes[eventData.type].isCombat then
			-- Don't be as inclined to investigae
			if self.state.eventTypes[eventData.type].sourceEntityRelation == "remoteCause" then
				return 25 -- Player rocket exploding
			else
				return 35 -- Player gunshot etc
			end
		end
		return 20 -- Player opening doors etc
	end
	-- Only investigate combat from friendly teams
	if self.state.eventTypes[eventData.type].isCombat then
		return 30
	end
	return 0
end

function game:tryInvestigateEvent(entity, eventData, visible, audible)
	if not (visible or audible) then
		return
	end

	local function trySetInvestigation()
		if self:getEventImportance(entity, eventData) <= 0 then
			return
		end
		entity.investigateLocation = {
			x = eventData.x,
			y = eventData.y,
			eventData = eventData,
			timeoutTimer = 0
		}
	end

	if entity == eventData.sourceEntity or not eventData.sourceEntity then
		return
	end

	if not entity.investigateLocation then
		trySetInvestigation()
		return
	end

	if
		self:getEventImportance(entity, eventData) >=
		self:getEventImportance(entity, entity.investigateLocation.eventData)
	then
		trySetInvestigation()
	end
end

return game
