local util = require("util")

local consts = require("consts")

local game = {}

function game:getMovementAction(entity)
	for _, listAction in ipairs(entity.actions) do
		if listAction.type == "move" then
			return listAction
		end
	end
	return nil
end

local uncopiedParameters = util.arrayToSet({
	"creatureTypeName"
})
function game:newCreatureEntity(parameters)
	local state = self.state

	local new = {}
	for k, v in pairs(parameters) do
		if not uncopiedParameters[k] then
			new[k] = v
		end
	end

	new.entityType = "creature"
	local creatureType = state.creatureTypes[parameters.creatureTypeName]
	new.creatureType = creatureType

	new.health = creatureType.maxHealth
	if creatureType.maxBlood then
		new.blood = creatureType.maxBlood
		new.bleedingAmount = 0
		new.bleedTimer = 0
		new.bleedHealTimer = 0
	end
	new.drownTimer = 0
	new.dead = false
	new.actions = {}

	if creatureType.inventorySize then
		new.inventory = {}
		for i = 1, creatureType.inventorySize do
			new.inventory[i] = {
				item = nil,
				otherItems = {} -- For stacking
				-- item is the top of a stack (as in FIFO data structure, as well as group of items), with the contents of otherItems being beneath it
			}
		end
	end

	state.entities[#state.entities+1] = new
	return new
end

function game:newItemEntity(x, y, itemData, extras)
	local state = self.state

	local new = {}
	new.entityType = "item"
	new.itemData = itemData
	new.x = x
	new.y = y

	if extras then
		for k, v in pairs(extras) do
			new[k] = v
		end
	end

	state.entities[#state.entities+1] = new
	return new
end

function game:updateEntitiesAndProjectiles()
	local state = self.state

	local entitiesToRemove = {}
	local function kill(entity, forceRemove)
		assert(not entity.dead, "Entity is already dead")
		assert(entity.entityType == "creature", "Can't kill non-creatures")
		entity.dead = true
		entity.deathTick = state.tick
		entity.actions = {}
		if entity.inventory then
			for i = 1, #entity.inventory do
				self:dropAllItemsFromSlot(entity, i, entity.x, entity.y)
			end
		end
		if forceRemove then
			entitiesToRemove[entity] = true
		end
	end
	local function flushEntityRemoval()
		local i = 1
		while i <= #state.entities do
			local entity = state.entities[i]
			if entitiesToRemove[entity] then
				local selectedEntityIndex = self:getSelectedEntityListIndex(self.state.cursor and self.state.cursor.selectedEntity or nil)

				entity.removed = true
				table.remove(state.entities, i)

				-- Remove links
				-- Flee info links are pruned when handled
				for _, entity2 in ipairs(state.entities) do
					if entity2.targetEntity == entity then
						entity2.targetEntity = nil
					end
					if entity2.hangingFrom == entity then
						entity2.hangingFrom = nil
					end
				end
				if entity == state.player then
					state.player = nil
				end
				if state.cursor and state.cursor.selectedEntity == entity then
					self:forceDeselectCursorEntity(selectedEntityIndex)
				end
			else
				i = i + 1
			end
		end
		entitiesToRemove = {} -- New list
	end

	local processedActions = {}
	local function processActions(actionTypeName)
		if processedActions[actionTypeName] then
			error("Duplicate processing of action type " .. actionTypeName)
		end
		processedActions[actionTypeName] = true
		local processFunction = state.actionTypes[actionTypeName].process
		for _, entity in ipairs(state.entities) do
			if entity.entityType ~= "creature" or entity.dead then
				goto continue
			end
			local i = 1
			while i <= #entity.actions do
				local action = entity.actions[i]
				local removed = false
				if action.type == actionTypeName then
					local resultInfo = processFunction(self, entity, action)
					if resultInfo then
						if actionTypeName == "interact" then -- or actionTypeName == "useHeldItem" then -- useHeldItem removes interactee by itself
							if resultInfo.deleteInteractee then
								if actionTypeName == "interact" then
									entitiesToRemove[action.targetEntity] = true
								end
							end
						end
					end
					if action.doneType then
						table.remove(entity.actions, i)
						removed = true
					end
				end
				if not removed then
					i = i + 1
				end
			end
		    ::continue::
		end
	end

	local function tickItems(tickFunction)
		for _, entity in ipairs(state.entities) do
			if entity.inventory then
				for _, slot in ipairs(entity.inventory) do
					if slot.item then
						tickFunction(slot.item, entity.x, entity.y)
					end
				end
			elseif entity.itemData then
				tickFunction(entity.itemData, entity.x, entity.y)
			end
		end
	end

	-- Reset buttons and tick levers
	tickItems(function(item, x, y)
		if item.itemType.isButton and item.pressed and not item.frozenState then
			item.pressed = false
			if item.onUnpress then
				item.onUnpress(self, item, x, y)
			end
			self:broadcastButtonStateChangedEvent(item, nil, false, x, y)
		elseif item.itemType.isLever then
			if item.active and item.onTickActive then
				item.onTickActive(self, item, x, y)
			elseif not item.active and item.onTickInactive then
				item.onTickInactive(self, item, x, y)
			end
		end
	end)


	-- AI visibility etc
	for _, entity in ipairs(state.entities) do
		assert(not (entity.targetEntity and entity.targetEntity.removed), "An entity is targetting a removed entity")

		if entity == state.player then
			-- TODO: Clear AI state?
			goto continue
		end

		-- Maintain investigation info
		if entity.investigateLocation then
			-- Clear if irrelevant

			local eventData = entity.investigateLocation.eventData
			if not eventData then
				entity.investigateLocation = nil
			else
				local wasFromCreature = eventData.sourceEntity and eventData.sourceEntity.entityType == "creature"

				local wasFromNonFriendly = wasFromCreature and self:getTeamRelation(entity.team, eventData.sourceEntity.team) ~= "friendly"
				local wasFromDeadNonFriendly = wasFromNonFriendly and eventData.sourceEntity.dead

				local wasFromFriendly = wasFromCreature and self:getTeamRelation(entity.team, eventData.sourceEntity.team) == "friendly"
				local wasAlert = eventData.type == "enemyAlert"
				local wasAlertFromFriendlyAboutDeadNonFriendly = wasAlert and wasFromFriendly and eventData.spottedEntity.dead

				if wasFromDeadNonFriendly or wasAlertFromFriendlyAboutDeadNonFriendly then
					entity.investigateLocation = nil
				end
			end

			if entity.investigateLocation then -- Check that we still have it
				entity.investigateLocation.timeoutTimer = entity.investigateLocation.timeoutTimer + 1
				if entity.investigateLocation.timeoutTimer >= consts.investigationTimeoutThreshold then
					entity.investigateLocation = nil
				else
					-- Any other maintenance to do
				end
			end
		end

		-- Fleeing behaviour
		-- Maintain current list and save its entries
		local fleeEntities = {}
		if entity.fleeFromEntities then
			for _, fleeInfo in ipairs(entity.fleeFromEntities) do
				if not fleeInfo.entity.removed and self:shouldEntityFlee(entity, fleeInfo.entity) then
					fleeEntities[fleeInfo.entity] = true
					if self:entityCanSeeEntity(entity, fleeInfo.entity) then
						fleeInfo.lastKnownX, fleeInfo.lastKnownY = fleeInfo.entity.x, fleeInfo.entity.y
					end
				else
					fleeInfo.remove = true
				end
			end
		end
		-- Look for new entries not in the current list
		for _, fleeEntity in ipairs(state.entities) do
			if fleeEntities[fleeEntity] or not self:shouldEntityFlee(entity, fleeEntity) then
				goto continue
			end
			if self:entityCanSeeEntity(entity, fleeEntity) then
				entity.fleeFromEntities = entity.fleeFromEntities or {}
				entity.fleeFromEntities[#entity.fleeFromEntities+1] = {lastKnownX = fleeEntity.x, lastKnownY = fleeEntity.y, entity = fleeEntity}
			end
		    ::continue::
		end
		-- Delete flee infos marked for removal
		if entity.fleeFromEntities then
			local fleeI = 1
			while fleeI <= #entity.fleeFromEntities do
				local fleeInfo = entity.fleeFromEntities[fleeI]
				if fleeInfo.remove then
					table.remove(entity.fleeFromEntities, fleeI)
				else
					fleeI = fleeI + 1
				end
			end
		end

		if entity.targetEntity and (entity.targetEntity.dead and not entity.creatureType.attackDeadTargets) then
			entity.targetEntity = nil
			entity.lastKnownTargetLocation = nil
		end

		if entity.targetEntity then
			if self:entityCanSeeEntity(entity, entity.targetEntity) then
				entity.lastKnownTargetLocation = {
					x = entity.targetEntity.x,
					y = entity.targetEntity.y
				}
			end
			if not self:getTeamRelation(entity.team, entity.targetEntity.team) == "enemy" then
				entity.targetEntity = nil
				entity.lastKnownTargetLocation = nil
			end
			goto continue
		end

		-- No target
		local potentialTarget = state.player -- Just look for player for now
		if not potentialTarget then
			goto continue
		end
		if not potentialTarget.dead then -- potentialTarget could be from a for loop
			if
				self:getTeamRelation(entity.team, potentialTarget.team) == "enemy" and
				self:entityCanSeeEntity(entity, potentialTarget)
			then
				local doSound = entity.creatureType.hasAlertSound
				self:broadcastEvent({
					x = entity.x,
					y = entity.y,
					sourceEntity = entity,
					type = "enemyAlert",
					alertType = doSound and "warcry" or "point",
					soundRange = doSound and entity.creatureType.vocalisationRange or nil,
					spottedEntity = potentialTarget,
					spottedEntityLocation = {x = potentialTarget.x, y = potentialTarget.y}
				})
				entity.targetEntity = potentialTarget
				entity.lastKnownTargetLocation = {
					x = entity.targetEntity.x,
					y = entity.targetEntity.y
				}
			end
		end

	    ::continue::
	end
	-- AI actions (player input already happened)
	for _, entity in ipairs(state.entities) do
		if entity.entityType ~= "creature" then
			goto continue
		end
		if #entity.actions > 0 or entity == state.player then
			goto continue
		end
		if entity.dead then
			goto continue
		end
		self:getAIActions(entity)
	    ::continue::
	end

	-- Actions (and other things)
	processActions("useHeldItem")
	processActions("shoot")
	processActions("mindAttack")
	self:updateProjectiles()
	processActions("move")
	processActions("melee")
	processActions("swapInventorySlot")
	processActions("reload")
	processActions("unload")
	processActions("drop")
	self.entityPickUps = {}
	processActions("pickUp")
	processActions("interact")
	for _, itemPickup in ipairs(self.entityPickUps) do
		if #itemPickup > 1 then
			-- TODO: If one of the entities is the player, announce pickup clash
			-- Only really needed if other entities can pick up items.
		else
			local entity = itemPickup[1]
			if entity then
				local slot = self:getBestFreeInventorySlotForItem(entity, itemPickup.item.itemData)
				if slot and self:addItemToSlot(entity, slot, itemPickup.item.itemData) then
					itemPickup.item.pickedUp = true
					entitiesToRemove[itemPickup.item] = true
				end
			end
		end
	end
	flushEntityRemoval()

	-- Damage, drowning, bleeding, explosions, gibbing, falling down pits, and screaming
	for _, entity in ipairs(state.entities) do
		if entity.hangingFrom then
			if not (entity.hangingFrom.x == entity.x and entity.hangingFrom.y == entity.y) then
				entity.hangingFrom = nil
			end
		end
		local tile = self:getTile(entity.x, entity.y)
		local anchored
		if entity.entityType == "item" and entity.itemData.itemType.anchorsOverPits then
			local anchorableNeighbours = self:getCheckedNeighbourTiles(entity.x, entity.y, function(x, y)
				local tile = self:getTile(x, y)
				return not tile or state.tileTypes[tile.type].solidity ~= "fall"
			end)
			anchored = #anchorableNeighbours > 0
		end
		if
			tile and
			state.tileTypes[tile.type].solidity == "fall" and
			(entity.entityType ~= "creature" or not (entity.creatureType.flying and not entity.dead)) and
			not entity.hangingFrom and
			not anchored
		then
			if entity.entityType == "creature" and not entity.dead then
				kill(entity, true)
			else
				entitiesToRemove[entity] = true
			end
			state.fallingEntities[#state.fallingEntities+1] = entity
		end

		if entity.entityType ~= "creature" then
			goto continue
		end
		if not entity.dead and entity.drownTimer and entity.creatureType.breathingTimerLength then
			if self:isDrowning(entity) then
				-- Mismatch; not breathing
				entity.drownTimer = math.min(entity.creatureType.breathingTimerLength, entity.drownTimer + 1)
				-- Drowning kill code is with health and blood based kills
			else
				-- Breathing. Recover drownTimer
				entity.drownTimer = math.max(0, entity.drownTimer - consts.drownTimerRecoveryRate)
			end

			if entity == state.player then
				-- NOTE: For announcement purposes, we assume the player is a human either drowning in a liquid or breathing in air, because that's the intended use of this code. Drowning still works if the player controls a fish, but the announcements will be wrong. We also assume that entering/exiting fluid is the player in an airlock.

				local newFluidMaterial = self:getCurrentLiquid(entity)
				local oldFluidMaterial = entity.initialSubmergedFluid

				-- Entering/exiting fluid
				if self:isDrowning(entity) and not entity.initialDrowningThisTick then
					self:announce("You breathe in before the " .. newFluidMaterial .. " fully consumes you.", "darkBlue")
				elseif not self:isDrowning(entity) and entity.initialDrowningThisTick then
					-- TODO: Announce based on how much time you had left
					-- self:announce("The " .. oldFluidMaterial .. " drains around you.", "blue")
					self:announce("You emerge from the " .. oldFluidMaterial .. ".", "blue")
				end

				-- Escalating drowning
				if self:isDrowning(entity) then
					local init = entity.initialDrownTimerThisTick
					local cur = entity.drownTimer
					local len = entity.creatureType.breathingTimerLength
					if init < len * 0.35 and cur >= len * 0.35 then
						self:announce("You begin to feel uncomfortable without air.", "darkBlue")
					end
					if init < len * 0.6 and cur >= len * 0.6 then
						self:announce("You feel sick. Your vision feels off.", "darkBlue")
					end
					if init < len * 0.8 and cur >= len * 0.8 then
						self:announce("You begin to panic, desperate for air.\nYou are suffering.", "darkCyan")
					end
					if init < len * 0.9 and cur >= len * 0.9 then
						self:announce("Your lungs refuse to hold.\nYou blurt out air and swallow " .. newFluidMaterial .. ".", "red")
					end
				end

				-- De-escalating drownTimer
				if not self:isDrowning(entity) then
					local init = entity.initialDrownTimerThisTick
					local cur = entity.drownTimer
					local len = entity.creatureType.breathingTimerLength
					if cur == 0 and init > 0 then
						self:announce("You are fully breathing again.", "lightGrey")
					end
					if init > len * 1/3 and cur <= len * 1/3 then
						self:announce("You can breathe less desperately.", "blue")
					end
					if init > len * 2/3 and cur <= len * 2/3 then
						self:announce("Relief washes over you as you receive air.", "darkBlue")
					end
				end
			end
		end

		if not entity.dead and entity.psychicDamage and entity.creatureType.psychicDamageDeathPoint then
			local noPsychicDamageTimerJustFinished
			if entity.psychicDamageTakenThisTick and entity.psychicDamageTakenThisTick > 0 then
				entity.noPsychicDamageTimer = consts.noPsychicDamageTimerLength
			else
				local was = entity.noPsychicDamageTimer and entity.noPsychicDamageTimer > 0
				entity.noPsychicDamageTimer = math.max(0, (entity.noPsychicDamageTimer or 0) - 1)
				local is = entity.noPsychicDamageTimer == 0 or not entity.noPsychicDamageTimer
				if was and not is then
					noPsychicDamageTimerJustFinished = true
				end
			end

			-- Damage should have been dealt at by this point in the tick
			local before = entity.psychicDamage
			if not entity.noPsychicDamageTimer or entity.noPsychicDamageTimer <= 0 then
				entity.psychicDamage = math.max(0, entity.psychicDamage - consts.telepathicMindAttackRecoveryRate)
			end
			local damageJustHitZero
			if before > 0 and entity.psychicDamage <= 0 then
				damageJustHitZero = true
			end
			-- Death occurs later in the code

			if entity == state.player then
				local init = (entity.initialPsychicDamageThisTick or 0)
				local cur = entity.psychicDamage
				local max = entity.creatureType.psychicDamageDeathPoint

				-- Escalating damage
				-- if init < max * 0.05 and cur >= max * 0.05 then
				if init <= 0 and cur > 0 then
					self:announce("You feel a gnawing anxiety...", "darkYellow")
				end
				if init < max * 0.25 and cur >= max * 0.25 then
					self:announce("You begin to hallucinate and can't think straight.", "darkYellow")
				end
				if init < max * 0.5 and cur >= max * 0.5 then
					self:announce("You slip into abject depression.", "yellow")
				end
				if init < max * 0.9 and cur >= max * 0.9 then
					 -- Canon fact: the player is *never* "severed from love and the divine"; they merely are made to feel so by psychic attacks
					self:announce("You feel severed from love and the divine.\nYou surrender yourself to meaninglessness.", "red")
				end

				-- De-escalating
				-- if (entity.noPsychicDamageTimer or 0) <= 0 then
				-- 	if cur == 0 and (init > 0 or noPsychicDamageTimerJustFinished) then
				-- 		self:announce("Your perception returns to normal.", "lightGrey")
				-- 	end
				-- 	if init > max * 1/3 and cur <= max * 1/3 then
				-- 		self:announce("You remember yourself.", "darkYellow")
				-- 	end
				-- 	if init > max * 2/3 and cur <= max * 2/3 then
				-- 		self:announce("Your confusion begins to ease, ever so slightly.", "yellow")
				-- 	end
				-- end

				local noPsychicDamageTimerAlreadyFinished = not noPsychicDamageTimerJustFinished and (entity.noPsychicDamageTimer or 0) <= 0
				if
					noPsychicDamageTimerJustFinished and cur == 0 or
					(noPsychicDamageTimerAlreadyFinished and damageJustHitZero)
				then
					-- TODO: Will this always be announced?
					self:announce("Your remember yourself.", "lightGrey")
				end
			end
		end

		local tile = self:getTile(entity.x, entity.y)
		if tile.explosionInfo then
			for _, damageInfo in ipairs(tile.explosionInfo.damagesThisTick) do
				self:damageEntity(entity, damageInfo.damage, damageInfo.sourceEntity, damageInfo.bleedRateAdd, damageInfo.instantBloodLoss)
			end
		end

		if entity.blood then -- Bleed even if dead
			-- Lose blood to bleeding
			local bled = math.floor((entity.bleedTimer + entity.bleedingAmount) / consts.bleedTimerLength)
			entity.bleedTimer = (entity.bleedTimer + entity.bleedingAmount) % consts.bleedTimerLength
			entity.blood = math.max(0, entity.blood - bled)
			if not entity.dead then
				local healRate = (entity.creatureType.bleedHealRate or 0) -- The effect of bandages etc could go here
				local healed
				if healRate > 0 then
					healed = math.floor((entity.bleedHealTimer + healRate) / consts.bleedHealTimerLength)
					entity.bleedHealTimer = (entity.bleedHealTimer + healRate) % consts.bleedHealTimerLength
				end
				entity.bleedingAmount = math.max(0, entity.bleedingAmount - (healed or 0))

				if entity.bleedingAmount <= 0 then
					entity.bleedTimer = 0
				end
			end

			-- Spatter blood lost this tick to the floor
			local lossPerSpatter = 6
			local sameTileSpatterThreshold = 3

			local bloodLoss = math.max(0, entity.initialBloodThisTick - entity.blood)
			if bloodLoss > 0 then
				local bloodRemaining = bloodLoss
				while bloodRemaining > 0 do
					local lossThisSpatter
					local forceSameTile = false
					if bloodRemaining == bloodLoss then
						-- First lot, make it lose 1 and be on the same tile
						lossThisSpatter = 1
						forceSameTile = true
					else
						lossThisSpatter = math.min(bloodRemaining, lossPerSpatter)
					end
					bloodRemaining = bloodRemaining - lossThisSpatter
					local x, y
					if forceSameTile or lossThisSpatter < sameTileSpatterThreshold then
						x, y = entity.x, entity.y
					else
						local minX = math.max(0, entity.x - 1)
						local maxX = math.min(state.map.width - 1, entity.x + 1)

						local minY = math.max(0, entity.y - 1)
						local maxY = math.min(state.map.height - 1, entity.y + 1)

						x = love.math.random(minX, maxX)
						y = love.math.random(minY, maxY)
					end
					self:addSpatter(x, y, entity.creatureType.bloodMaterialName, lossThisSpatter)
				end
			end
		end

		for _, sourceInfo in ipairs(state.damagesQueue) do
			local done = false
			for _, destination in ipairs(sourceInfo) do
				if entity ~= destination.entity then
					goto continue
				end

				local sourceEntityOrTypeName = sourceInfo.source
				local damage = destination.total
				self:broadcastEvent({
					-- sourceEntity means "entity associated with the event" in broadcastEvent, and in damageEntity it means "entity which is the source of damage". They're not the same here!
					sourceEntity = entity,
					damageDealer = sourceEntityOrTypeName,
					x = entity.x,
					y = entity.y,
					type = "damageReceived",
					damageDealt = damage,
				})
				done = true
				do break end

			    ::continue::
			end
			if done then
				break
			end
		end
		-- state.damagesQueue is set to a new table after all entities are handled by this loop

		if not entity.dead then
			if
				entity.health <= 0 or
				(entity.blood and entity.blood <= 0) or
				(entity.drownTimer and entity.creatureType.breathingTimerLength and entity.drownTimer >= entity.creatureType.breathingTimerLength) or
				(entity.psychicDamage and entity.creatureType.psychicDamageDeathPoint and entity.psychicDamage >= entity.creatureType.psychicDamageDeathPoint)
			then
				kill(entity)
			end
		end

		local gibbed = false
		local gibThreshold = -entity.creatureType.maxHealth * 2.2
		if entity.health <= gibThreshold then
			gibbed = true

			local entityFleshMaterial = entity.creatureType.fleshMaterialName or "fleshRed"

			self:broadcastEvent({
				sourceEntity = entity,
				x = entity.x,
				y = entity.y,
				type = "gibbing",
				gibMaterial = entityFleshMaterial,
				soundRange = 10,
				isDeath = true
			})

			entitiesToRemove[entity] = true
			local gibForce = (gibThreshold - entity.health) / entity.creatureType.maxHealth ^ 0.7 -- Non-integer
			local fleshAmount = math.floor(entity.creatureType.maxHealth ^ 0.85 * 2.8)
			local extraBlood = entity.creatureType.gibBloodRelease or entity.creatureType.maxBlood and math.floor(entity.creatureType.maxBlood * 0.65) or 0
			local bloodAmount = (entity.blood or 0) + extraBlood
			local bloodSaveAmount = math.ceil(bloodAmount * 0.2)
			bloodAmount = bloodAmount - bloodSaveAmount -- For more blood-only gibs
			local gibs = {}
			local gibCount = math.min(fleshAmount, math.floor(gibForce * 1/3) + 2)
			local function newGib()
				local speed = (love.math.random() * 0.25 + 1) * math.min(24, gibForce)
				local range = math.min(6, math.ceil(speed / 16))
				local angle = love.math.random() * consts.tau
				local subtickMoveTimerLength = math.ceil(25 * consts.projectileSubticks / speed)
				local r = consts.spreadRetargetDistance
				local startX, startY = entity.x, entity.y
				local endX = math.floor(math.cos(angle) * r + 0.5) + startX -- Round
				local endY = math.floor(math.sin(angle) * r + 0.5) + startY
				local new = {
					startDropped = speed < 4,
					x = startX,
					y = startY,
					startX = startX,
					startY = startY,
					range = range,
					aimX = endX,
					aimY = endY,
					subtickMoveTimerLength = subtickMoveTimerLength,
					subtickMoveTimerLengthChange = 24,
					subtickMoveTimerLengthMax = subtickMoveTimerLength * 2,
					fleshMaterial = entityFleshMaterial,
					fleshAmount = 0,
					bloodMaterial = entity.creatureType.bloodMaterialName,
					bloodAmount = 0,
					fleshTile = consts.gibFleshTiles[love.math.random(#consts.gibFleshTiles)]
				}
				-- For blood trails
				if entity.creatureType.bloodMaterialName then
					local bloodAmountMoved = math.min(bloodAmount, love.math.random(1, 3))
					bloodAmount = bloodAmount - bloodAmountMoved
					new.bloodAmount = new.bloodAmount + bloodAmountMoved
				end
				return new
			end
			for i = 1, gibCount do
				gibs[i] = newGib()
			end
			local fleshDistributionChunkSize = 2
			while fleshAmount > 0 do
				local gib = gibs[love.math.random(#gibs)]
				local fleshAmountMoved = math.min(fleshAmount, fleshDistributionChunkSize)
				fleshAmount = fleshAmount - fleshAmountMoved
				gib.fleshAmount = gib.fleshAmount + fleshAmountMoved
			end
			local bloodDistributionChunkSize = 1
			if entity.creatureType.bloodMaterialName then
				while bloodAmount > 0 do
					local gib = gibs[love.math.random(#gibs)]
					local bloodAmountMoved = math.min(bloodAmount, bloodDistributionChunkSize)
					bloodAmount = bloodAmount - bloodAmountMoved
					gib.bloodAmount = gib.bloodAmount + bloodAmountMoved
				end
			end
			while bloodSaveAmount > 0 do
				local bloodTaken = math.min(bloodSaveAmount, love.math.random(1, 3))
				bloodSaveAmount = bloodSaveAmount - bloodTaken
				local newBloodOnlyGib = newGib()
				newBloodOnlyGib.bloodAmount = bloodTaken
				gibs[#gibs+1] = newBloodOnlyGib
			end
			local i = 1
			while i <= #gibs do
				local gib = gibs[i]
				if gib.fleshAmount <= 0 and gib.bloodAmount <= 0 then
					table.remove(gibs, i)
				else
					i = i +1
				end
			end
			gibs = util.shuffle(gibs)
			for _, gib in ipairs(gibs) do
				if not gib.startDropped then
					self:initProjectileTrajectory(gib, gib.startX, gib.startY, gib.aimX, gib.aimY)
					state.gibs[#state.gibs+1] = gib
				else
					gib.currentX = gib.startX
					gib.currentY = gib.startY
					self:dropGib(gib)
				end
			end
		end

		if
			not gibbed and entity.damageTakenThisTick and
			(
				entity.dead or
				entity.creatureType.painDamageThreshold and entity.damageTakenThisTick >= entity.creatureType.painDamageThreshold
			)
		then
			if not entity.dead or entity.deathTick == state.tick then
				self:broadcastEvent({
					sourceEntity = entity,
					x = entity.x,
					y = entity.y,
					type = "pain",
					soundRange = entity.creatureType.vocalisationRange,
					painSound = entity.creatureType.vocalisationRange and "scream",
					isDeath = entity.dead
				})
			end
		end

		::continue::
	end
	state.damagesQueue = {} -- Accumulate anything for next tick
	flushEntityRemoval()

	for _, entity in ipairs(state.entities) do
		if not entity.inventory then
			goto continue
		end
		if not entity.inventory.selectedSlot then
			goto continue
		end
		if not entity.inventory[entity.inventory.selectedSlot].item then
			entity.inventory.selectedSlot = nil
		end
	    ::continue::
	end

	tickItems(function(item, x, y)
		if item.shotCooldownTimer then
			item.shotCooldownTimer = item.shotCooldownTimer - 1
			if item.shotCooldownTimer <= 0 then
				item.shotCooldownTimer = nil
				if not item.itemType.manual then
					self:cycleGun(item, x, y)
				end
			end
		end
		if item.itemType.energyWeapon then
			if not item.insertedMagazine then
				item.chargeState = "hold"
			else
				if item.chargeState == "fromBattery" then
					local rate = math.min(item.itemType.energyChargeRate, item.insertedMagazine.itemType.energyDischargeRate)
					local spaceInWeapon = math.max(0, item.itemType.maxEnergy - item.storedEnergy)
					local give = math.min(rate, item.insertedMagazine.storedEnergy)
					local finalGive = math.min(spaceInWeapon, give)
					item.storedEnergy = item.storedEnergy + finalGive
					item.insertedMagazine.storedEnergy = item.insertedMagazine.storedEnergy - finalGive
				elseif item.chargeState == "toBattery" then
					local rate = math.min(item.itemType.energyDischargeRate, item.insertedMagazine.itemType.energyChargeRate)
					local spaceInBattery = math.max(0, item.insertedMagazine.itemType.maxEnergy - item.insertedMagazine.storedEnergy)
					local give = math.min(rate, item.storedEnergy)
					local finalGive = math.min(spaceInBattery, give)
					item.insertedMagazine.storedEnergy = item.insertedMagazine.storedEnergy + finalGive
					item.storedEnergy = item.storedEnergy - finalGive
				end
			end
		end
	end)

	for _, actionType in ipairs(state.actionTypes) do
		assert(processedActions[actionType.name], "Did not process action type " .. actionType.name)
	end
end

function game:entityCanSeeTile(entity, x, y)
	if not entity.creatureType.sightDistance then
		return false
	end

	local distance = self:distance(entity.x, entity.y, x, y)
	if distance <= entity.creatureType.sightDistance then -- Uses <= like in visibility.lua's rangeLimit check
		return self:hitscan(entity.x, entity.y, x, y)
	end
	return false
end

function game:entityCanSeeEntity(seer, seen)
	return self:entityCanSeeTile(seer, seen.x, seen.y)
end

function game:projectileCanPathFromEntityToEntity(source, destination)
	return self:hitscan(source.x, source.y, destination.x, destination.y, self.tileBlocksAirMotion)
end

function game:getEntityDisplayName(entity)
	if entity.entityType == "creature" then
		return entity.creatureType.displayName
	else
		return "TODO: Display name"
	end
end

function game:damageEntity(entity, damage, source, bleedRateAdd, instantBloodLoss)
	-- Deal

	local state = self.state
	entity.health = entity.health - damage
	if entity.blood then
		entity.blood = math.max(0, entity.blood - (instantBloodLoss or 0))
		entity.bleedingAmount = math.min(consts.maxBleedingAmount, entity.bleedingAmount + (bleedRateAdd or 0))
	end

	-- Record

	local dealtDamageList
	for _, sourceList in ipairs(state.damagesQueue) do
		if sourceList.source == source then
			dealtDamageList = sourceList
			break
		end
	end
	if not dealtDamageList then
		dealtDamageList = {source = source}
		state.damagesQueue[#state.damagesQueue+1] = dealtDamageList
	end

	local damageReceiverInfo
	for _, damageReceiver in ipairs(dealtDamageList) do
		if damageReceiver.entity == entity then
			damageReceiverInfo = damageReceiver
			break
		end
	end
	if not damageReceiverInfo then
		damageReceiverInfo = {entity = entity, total = 0}
		dealtDamageList[#dealtDamageList+1] = damageReceiverInfo
	end
	damageReceiverInfo.total = damageReceiverInfo.total + damage

	-- Only damages paired with sources are recorded above, so we also need to aggregate all damage that a creature receives each tick

	entity.damageTakenThisTick = (entity.damageTakenThisTick or 0) + damage
end

function game:getTileEntityLists()
	local lists = {}
	for _, entity in ipairs(self.state.entities) do
		local x, y = entity.x, entity.y
		if not lists[x] then
			lists[x] = {}
		end
		if not lists[x][y] then
			lists[x][y] = {
				selectable = {},
				all = {}
			}
		end
		local tileList = lists[x][y]
		if self:cursorCanSelectEntity(entity, false) then
			tileList.selectable[#tileList.selectable+1] = entity
		end
		tileList.all[#tileList.all+1] = entity
	end
	return lists
end

function game:entityListChanged(x, y, listType)
	local previous
	if self.state.previousTileEntityLists then
		if self.state.previousTileEntityLists[x] then
			previous = self.state.previousTileEntityLists[x][y]
		end
	end

	local current
	if self.state.tileEntityLists then
		if self.state.tileEntityLists[x] then
			current = self.state.tileEntityLists[x][y]
		end
	end

	current = current and current[listType] or {}
	previous = previous and previous[listType] or {}
	return not util.arraysEqual(current, previous)
end

function game:updateEntitiesToDraw(dt)
	local state = self.state

	local incrementEntityDisplays = false
	state.incrementEntityDisplaysTimer = state.incrementEntityDisplaysTimer - dt
	if state.incrementEntityDisplaysTimer <= 0 then
		state.incrementEntityDisplaysTimer = state.incrementEntityDisplaysTimerLength
		incrementEntityDisplays = true
	end
	state.incrementingEntityDisplays = incrementEntityDisplays -- Just so that we can guarantee at least one frame of switching indicator

	local previousEntityListDrawsByTile = state.entityListDrawsByTile or {}
	state.entityListDrawsByTile = nil
	local entityListDrawsByTile = {}
	local entitiesToDraw = {}

	for x, column in pairs(state.tileEntityLists) do
		for y, listSet in pairs(column) do
			local list = listSet.all
			local prevEntity = previousEntityListDrawsByTile[x] and previousEntityListDrawsByTile[x][y]
			if #list > 0 then
				local prevEntityIndex
				for i, entity in ipairs(list) do
					if entity == prevEntity then
						prevEntityIndex = i
						break
					end
				end

				local currentIndex
				if prevEntityIndex then
					if incrementEntityDisplays then
						currentIndex = prevEntityIndex + 1
						currentIndex = (currentIndex - 1) % #list + 1
					else
						currentIndex = prevEntityIndex
					end
				else
					currentIndex = 1
				end
				local entityToDraw = list[currentIndex]

				entityListDrawsByTile[x] = entityListDrawsByTile[x] or {}
				entityListDrawsByTile[x][y] = entityToDraw
				entitiesToDraw[#entitiesToDraw+1] = entityToDraw
			end
		end
	end

	state.entitiesToDraw = entitiesToDraw
	state.entityListDrawsByTile = entityListDrawsByTile
end

function game:abilityShoot(entity, action, ability, targetEntity)
	local aimX, aimY = entity.x + action.relativeX, entity.y + action.relativeY
	local entityHitRandomSeed = love.math.random(0, 2 ^ 32 - 1) -- So that you can't shoot every entity on a single tile with a single spread
	for _=1, ability.shotCount or 1 do
		local spread = ability.spread or 0
		spread = spread ~= 0 and spread or nil
		self:newProjectile({
			shooter = entity,
			startX = entity.x,
			startY = entity.y,
			tile = ability.projectileTile,
			colour = ability.projectileColour,
			subtickMoveTimerLength = ability.projectileSubtickMoveTimerLength,
			subtickMoveTimerLengthChange = ability.projectileSubtickMoveTimerLengthChange,
			subtickMoveTimerLengthMin = ability.projectileSubtickMoveTimerLengthMin,
			subtickMoveTimerLengthMax = ability.projectileSubtickMoveTimerLengthMax,
			damage = ability.damage,
			bleedRateAdd = ability.bleedRateAdd,
			instantBloodLoss = ability.instantBloodLoss,
			range = ability.range,
			entityHitRandomSeed = entityHitRandomSeed,
			projectileExplosionProjectiles = ability.projectileExplosionProjectiles,
			maxPierces = ability.maxPierces,
			explosionRadius = ability.projectileExplosionRadius,
			explosionDamage = ability.projectileExplosionDamage,

			aimX = aimX,
			aimY = aimY,
			bulletSpread = spread,

			trailParticleInfo = ability.trailParticleInfo,

			targetEntity = targetEntity -- Can be nil
		})
	end
end

function game:getAttackStrengths(entity)
	local heldItem = self:getHeldItem(entity)
	if heldItem and heldItem.itemType.isMeleeWeapon then
		return heldItem.itemType.meleeDamage, heldItem.itemType.meleeBleedRateAdd, heldItem.itemType.meleeInstantBloodLoss
	end
	return entity.creatureType.meleeDamage, entity.creatureType.meleeBleedRateAdd, entity.creatureType.meleeInstantBloodLoss
end

function game:isEntitySwimming(entity)
	local tile = self:getTile(entity.x, entity.y)
	if not tile then
		return
	end
	return not not tile.liquid
end

function game:getMoveTimerLength(entity)
	return self:isEntitySwimming(entity) and (entity.creatureType.swimMoveTimerLength or
		entity.creatureType.moveTimerLength and entity.creatureType.moveTimerLength * 2
	) or entity.creatureType.moveTimerLength
end

function game:isDrowning(entity) -- Returns whether drowning as a boolean, and also the cause as a string. Causes: "noAir", "airDrowning"
	return
		self:isEntitySwimming(entity) ~= not not entity.creatureType.aquatic,
		entity.creatureType.aquatic and "airDrowning" or "noAir"
end

function game:getCurrentLiquid(entity)
	local tile = self:getTile(entity.x, entity.y)
	if not tile then
		return
	end
	local liquid = tile.liquid
	if not liquid then
		return
	end
	return liquid.material
end

function game:shouldEntityFlee(entity, potentialFleeFromEntity)
	-- Monsters that flee when sufficiently wounded?
	if potentialFleeFromEntity.entityType ~= "creature" then
		return false
	end
	if potentialFleeFromEntity.dead then
		return false
	end
	if entity.team == "critter" and potentialFleeFromEntity.team ~= "critter" then
		return true
	end
	return false
end

return game
