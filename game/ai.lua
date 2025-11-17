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
		if not tile.doorData.open and not (
			entity.creatureType.canOpenDoors and
			tile.doorData.entity.itemData.itemType.interactable and
			not tile.doorData.lockName
		) then
			return false
		end
	end
	return self:getWalkable(tileX, tileY, true, entity.creatureType.flying)
end

local function getPathfindingResult(self, entity, startTile, endTile, keepLineOfSight)
	local state = self.state

	local canSeeEnd = keepLineOfSight and self:entityCanSeeTile(entity, endTile.x, endTile.y)

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
		if
			keepLineOfSight and
			not (
				canSeeEnd and
				entity.creatureType.sightDistance and
				self:distance(tileX, tileY, endTile.x, endTile.y) <= entity.creatureType.sightDistance and
				self:hitscan(tileX, tileY, endTile.x, endTile.y)
			)
		then
			return false
		end
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
	return result
end

local function getPathfindingAction(self, entity, targetLocationX, targetLocationY, dontWalkInto, investigating, keepLineOfSight)
	local startTile = self:getTile(entity.x, entity.y)
	local endTile = self:getTile(targetLocationX, targetLocationY)
	if startTile and endTile then
		local result = getPathfindingResult(self, entity, startTile, endTile, keepLineOfSight)
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

local function getPathfindingDistance(self, entity, startX, startY, endX, endY)
	-- TODO: MUST OPTIMISE!!
	local startTile = self:getTile(startX, startY)
	local endTile = self:getTile(endX, endY)
	if not (startTile and endTile) then
		return
	end
	if startX == startY and endX == endY then
		return 0
	end
	local result = getPathfindingResult(self, entity, startTile, endTile)
	if result then
		return #result - 1
	end
end

local function chase(self, entity, sameTileMelee, keepLineOfSight)
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
		return getPathfindingAction(self, entity, targetLocationX, targetLocationY, dontWalkInto, investigating, keepLineOfSight)
	end
end

local function moveAwayFromEntity(self, entity, fleeInfo, keepLineOfSight)
	-- Get walkable neighbours
	local function checkFunction(tileX, tileY)
		return tilePathCheckFunction(self, tileX, tileY, entity)
	end
	local potentialNextSteps = self:getCheckedNeighbourTiles(entity.x, entity.y, checkFunction, true)

	-- Get tile which is most aligned with the direction away from closest flee from entity

	local fleeDistance = self:distance(entity.x, entity.y, fleeInfo.lastKnownX, fleeInfo.lastKnownY)

	local canSeeTarget = self:entityCanSeeEntity(entity, entity.targetEntity)
	local nextTargetX, nextTargetY
	if canSeeTarget then
		nextTargetX, nextTargetY = entity.targetEntity.x, entity.targetEntity.y
		local targetMove = self:getMovementAction(entity.targetEntity)
		if targetMove and targetMove.timer == 1 then
			local ox, oy = self:getDirectionOffset(targetMove.direction)
			nextTargetX, nextTargetY = nextTargetX + ox, nextTargetY + oy
		end
	end

	local nextTile
	if fleeDistance == 0 then
		nextTile = potentialNextSteps[love.math.random(#potentialNextSteps)]
	else
		if not fleeInfo then
			return
		end
		local fleeX, fleeY = entity.x - fleeInfo.lastKnownX, entity.y - fleeInfo.lastKnownY
		local fleeDirX, fleeDirY = fleeX / fleeDistance, fleeY / fleeDistance

		local function getScore(x, y)
			local stepX, stepY = x - entity.x, y - entity.y
			local stepDist = self:length(stepX, stepY)
			if stepDist == 0 then
				return -math.huge
			end
			local stepDirX, stepDirY = stepX / stepDist, stepY / stepDist
			if
				self:distance(x, y, fleeInfo.lastKnownX, fleeInfo.lastKnownY) < fleeDistance or
				keepLineOfSight and not (
					canSeeTarget and
					entity.creatureType.sightDistance and
					self:distance(x, y, nextTargetX, nextTargetY) <= entity.creatureType.sightDistance and
					self:hitscan(x, y, nextTargetX, nextTargetY)
				)
			then
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
				local dist = self:distance(tile.x, tile.y, fleeInfo.lastKnownX, fleeInfo.lastKnownY)
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

local function fleeLastKnownFleeFromEntityPositions(self, entity)
	-- Lots of complexity that didn't really end up doing what I wanted.

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

	if not closestFleeFromInfo then
		return
	end

	return moveAwayFromEntity(self, entity, closestFleeFromInfo, false)
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

local function tryMindAttackTargetEntity(self, entity)
	local targetEntity = entity.targetEntity
	if not targetEntity then
		return
	end
	if not self:entityCanSeeEntity(entity, targetEntity) then
		return
	end
	return self.state.actionTypes.mindAttack.construct(self, entity, targetEntity)
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

local function areTilesInPreferredRange(self, range, startX, startY, endX, endY)
	local distance = self:distance(startX, startY, endX, endY)
	local preferredDistance = range
	local delta = preferredDistance - distance
	local actualStatus = delta > 0 and "tooClose" or delta < 0 and "tooFar" or delta == 0 and "atDistance"
	local closeEnough = math.abs(delta) < 1.5
	return closeEnough, actualStatus
end

local function isInPreferredRangeOfTargetEntity(self, entity)
	return areTilesInPreferredRange(self, entity.creatureType.preferredEngagementRange, entity.x, entity.y, entity.targetEntity.x, entity.targetEntity.y)
end

local function moveBackToPreferredRangeOfTargetEntity(self, entity)
	local targetLocationX, targetLocationY
	if self:entityCanSeeEntity(entity, entity.targetEntity) then
		targetLocationX, targetLocationY = entity.targetEntity.x, entity.targetEntity.y
	elseif entity.lastKnownTargetLocation then
		targetLocationX, targetLocationY = entity.lastKnownTargetLocation.x, entity.lastKnownTargetLocation.y
	end
	local fakeFleeInfo = {
		lastKnownX = targetLocationX,
		lastKnownY = targetLocationY,
		entity = entity.targetEntity
	}
	return moveAwayFromEntity(self, entity, fakeFleeInfo, true)
end

local function pathfindToClosestTileWithSightToTilePrioritisingPreferredRange(self, entity, tileToSeeX, tileToSeeY)
	local sightDistance = entity.creatureType.sightDistance
	if not sightDistance then
		return
	end

	-- TODO: Optimise... lots of line-of-sight checks
	local closestVisibleTile -- Closest visible tile, prioritising ones that are in the preferred engagement range
	local closestVisibleTileDistance
	local closestVisibleTileIsInRange
	for tileToWalkToX = tileToSeeX - sightDistance, tileToSeeX + sightDistance do
		for tileToWalkToY = tileToSeeY - sightDistance, tileToSeeY + sightDistance do
			local tile = self:getTile(tileToWalkToX, tileToWalkToY)
			if not tile then
				goto continue
			end

			 -- Will we be able to see it?
			local willBeVisible =
				self:distance(tileToWalkToX, tileToWalkToY, tileToSeeX, tileToSeeY) <= entity.creatureType.sightDistance and
				self:hitscan(tileToWalkToX, tileToWalkToY, tileToSeeX, tileToSeeY)

			local isWalkable = tilePathCheckFunction(self, tileToWalkToX, tileToWalkToY, entity)

			if willBeVisible and isWalkable then
				local currentToWalkDistance = getPathfindingDistance(self, entity, entity.x, entity.y, tileToWalkToX, tileToWalkToY)
				if not currentToWalkDistance then
					goto continue
				end

				local isInRange = entity.creatureType.preferredEngagementRange and areTilesInPreferredRange(self, entity.creatureType.preferredEngagementRange, tileToWalkToX, tileToWalkToY, tileToSeeX, tileToSeeY)

				local wouldBeLeavingRange = not isInRange and closestVisibleTileIsInRange

				if tile.x == entity.x and tile.y == entity.y and not wouldBeLeavingRange then
					closestVisibleTile = tile
					closestVisibleTileDistance = currentToWalkDistance
					closestVisibleTileIsInRange = isInRange
					break
				end

				if not closestVisibleTile or currentToWalkDistance < closestVisibleTileDistance and not wouldBeLeavingRange or isInRange and not closestVisibleTileIsInRange then
					closestVisibleTile = tile
					closestVisibleTileDistance = currentToWalkDistance
					closestVisibleTileIsInRange = isInRange
				end
			end
		    ::continue::
		end
	end

	if closestVisibleTile then
		return getPathfindingAction(self, entity, closestVisibleTile.x, closestVisibleTile.y, false, false)
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

	local newAction
	local waitForSameTileMelee

	if entity.fleeFromEntities and #entity.fleeFromEntities > 0 then
		newAction = fleeLastKnownFleeFromEntityPositions(self, entity)
	elseif entity.targetEntity then
		local canSee = self:entityCanSeeEntity(entity, entity.targetEntity)
		local fightAction
		if canSee then
			local shootType =
				self:getHeldItem(entity) and self:getHeldItem(entity).itemType.isGun and "gun" or
				entity.creatureType.telepathicMindAttackDamageRate and "mindAttack" or
				entity.creatureType.projectileAbilities and #entity.creatureType.projectileAbilities > 0 and "ability" or
				nil
			-- Don't shoot if the entity is dead (we'd only be here if entity.creatureType.attackDeadTargets is true, and its purpose is to make monsters destroy corpses, which seems better suited for melee)
			if entity.targetEntity.dead then
				shootType = nil
			end
			-- Random chance (per tick) to not choose to shoot
			local aggressiveness =
				(
					entity.creatureType.engagesAtRange and
					not isInPreferredRangeOfTargetEntity(self, entity) and
					entity.creatureType.wrongRangeShootAggressiveness
				) or
				entity.creatureType.shootAggressiveness
			if state.meleeOnly or love.math.random() >= (aggressiveness or 1) then
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
				elseif shootType == "mindAttack" then
					fightAction = tryMindAttackTargetEntity(self, entity)
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
		if not entity.creatureType.engagesAtRange then
			newAction = chase(self, entity, waitForSameTileMelee)
		else
			if entity.targetEntity then
				if self:entityCanSeeEntity(entity, entity.targetEntity) then
					-- Engage at a certain range from the player but always be visible
					local isAtRange, actualStatus = isInPreferredRangeOfTargetEntity(self, entity)
					if isAtRange then
						-- No new action
					elseif actualStatus == "tooFar" then
						newAction = chase(self, entity, waitForSameTileMelee, true)
					else
						-- actualStatus == "tooClose"
						newAction = moveBackToPreferredRangeOfTargetEntity(self, entity) -- While keeping line of sight to player
					end
				else
					-- newAction =
					-- 	entity.lastKnownTargetLocation and pathfindToClosestTileWithSightToTilePrioritisingPreferredRange(self, entity, entity.lastKnownTargetLocation.x, entity.lastKnownTargetLocation.y)
					-- 	-- chase(self, entity, waitForSameTileMelee)

					-- TEMP: Leads to some silly behaviour
					newAction = chase(self, entity, waitForSameTileMelee)
				end
			end
		end
	end

	if entity.targetEntity and not newAction then
		if entity.creatureType.telepathicMindAttackDamageRate then
			newAction = tryMindAttackTargetEntity(self, entity)
		end
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
