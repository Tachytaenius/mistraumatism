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

function game:getDestinationTile(entity)
	local action = self:getMovementAction(entity)
	if not action then
		return nil
	end
	local offsetX, offsetY = self:getDirectionOffset(action.direction)
	return entity.x + offsetX, entity.y + offsetY
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
					processFunction(self, entity, action)
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

	local entitiesToRemove = {}
	local function kill(entity)
		entity.dead = true
		entity.deathTick = state.tick
		entity.actions = {}
		if entity.inventory then
			for i = 1, #entity.inventory do
				self:dropAllItemsFromSlot(entity, i, entity.x, entity.y)
			end
		end
		-- entitiesToRemove[entity] = true
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
				for _, entity2 in ipairs(state.entities) do
					if entity2.targetEntity == entity then
						entity2.targetEntity = nil
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

	-- AI visibility etc
	for _, entity in ipairs(state.entities) do
		assert(not (entity.targetEntity and entity.targetEntity.removed), "An entity is targetting a removed entity")

		if entity == state.player then
			goto continue
		end

		if entity.targetEntity and entity.targetEntity.dead then
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
				-- TODO: Announce monster wakeup etc?
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
		if not entity.entityType == "creature" or entity.dead then
			goto continue
		end
		self:getAIActions(entity)
	    ::continue::
	end

	-- Actions (and other things)
	processActions("useHeldItem")
	processActions("shoot")
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
				local slot = self:getFirstFreeInventorySlotForItem(entity, itemPickup.item.itemData)
				if slot and self:addItemToSlot(entity, slot, itemPickup.item.itemData) then
					itemPickup.item.pickedUp = true
					entitiesToRemove[itemPickup.item] = true
				end
			end
		end
	end
	flushEntityRemoval()

	-- Damage and bleeding
	for _, entity in ipairs(state.entities) do
		if entity.entityType ~= "creature" then
			goto continue
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
			local lossPerSpatter = 8
			local sameTileSpatterThreshold = 4

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
		if not entity.dead then
			if entity.health <= 0 or (entity.blood and entity.blood <= 0) then
				kill(entity)
			end
		end
	    ::continue::
	end

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

	local function tickItem(item, x, y)
		if item.shotCooldownTimer then
			item.shotCooldownTimer = item.shotCooldownTimer - 1
			if item.shotCooldownTimer <= 0 then
				item.shotCooldownTimer = nil
				if not item.itemType.manual then
					self:cycleGun(item, x, y)
				end
			end
		end
	end
	for _, entity in ipairs(state.entities) do
		if entity.inventory then
			for _, slot in ipairs(entity.inventory) do
				if slot.item then
					tickItem(slot.item, entity.x, entity.y)
				end
			end
		elseif entity.itemData then
			tickItem(entity.itemData, entity.x, entity.y)
		end
	end

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

function game:damageEntity(entity, damage, sourceEntity, bleedRateAdd, instantBloodLoss)
	-- Deal

	local state = self.state
	entity.health = entity.health - damage
	entity.blood = math.max(0, entity.blood - (instantBloodLoss or 0))
	entity.bleedingAmount = math.min(consts.maxBleedingAmount, entity.bleedingAmount + (bleedRateAdd or 0))

	-- Record

	-- TODO: Non-entity sources

	local dealtDamageList
	for _, sourceEntityList in ipairs(state.damagesThisTick) do
		if sourceEntityList.sourceEntity == sourceEntity then
			dealtDamageList = sourceEntityList
			break
		end
	end
	if not dealtDamageList then
		dealtDamageList = {sourceEntity = sourceEntity}
		state.damagesThisTick[#state.damagesThisTick+1] = dealtDamageList
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
			damage = ability.damage,
			bleedRateAdd = ability.bleedRateAdd,
			instantBloodLoss = ability.instantBloodLoss,
			range = ability.range,
			entityHitRandomSeed = entityHitRandomSeed,

			aimX = aimX,
			aimY = aimY,
			bulletSpread = spread,

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

return game
