local game = {}

function game:isDoorBlocked(doorEntity)
	for _, entity in ipairs(self.state.entities) do
		if entity.x == doorEntity.x and entity.y == doorEntity.y and entity ~= doorEntity then
			return true
		end
	end
	return false
end

function game:broadcastHatchStateChangedEvent(tile, opener, manual)
	local hatchState = self.state.tileTypes[tile.type].hatchState
	if not hatchState then
		return
	end
	self:broadcastEvent({
		sourceEntity = opener,
		x = tile.x,
		y = tile.y,
		type = "hatchChangeState",
		soundRange = self.state.tileTypes[tile.type].stateChangeSoundRange,
		soundType = hatchState == "open" and "hatchOpening" or "hatchClosing"
	})
end

function game:broadcastDoorStateChangedEvent(tile, opener, manual)
	self:broadcastEvent({
		sourceEntity = opener,
		x = tile.x,
		y = tile.y,
		type = "doorChangeState",
		soundRange = tile.doorData.entity.itemData.itemType.stateChangeSoundRange,
		soundType = tile.doorData.open and "doorOpening" or "doorClosing"
	})
end

function game:broadcastButtonStateChangedEvent(item, interactor, manual, x, y)
	self:broadcastEvent({
		sourceEntity = interactor,
		x = x,
		y = y,
		type = "buttonChangeState",
		soundRange = item.itemType.stateChangeSoundRange,
		soundType = item.pressed and "buttonPressed" or "buttonReset"
	})
end

function game:broadcastLeverStateChangedEvent(item, interactor, manual, x, y)
	self:broadcastEvent({
		sourceEntity = interactor,
		x = x,
		y = y,
		type = "leverChangeState",
		soundRange = item.itemType.stateChangeSoundRange,
		soundType = item.active and "leverActivated" or "leverDeactivated"
	})
end

function game:loadInteractionTypes()
	local interactionTypes = {}

	-- Self is game instance

	interactionTypes.door = {}
	local function getDoorTileDoorData(doorEntity)
		local tile = doorEntity.doorTile
		if not tile then
			return
		end
		return tile.doorData
	end
	function interactionTypes.door:startInfoWorld(interactor, interactionType, interactee)
		if interactionType ~= "world" then
			return
		end
		local timerLength = 7
		local doorData = getDoorTileDoorData(interactee)
		local info = {
			doneDoorOpenState = doorData and not doorData.open
		}
		return timerLength, info
	end
	function interactionTypes.door:resultWorld(interactor, interactionType, interactee, info)
		if interactionType ~= "world" then
			return
		end
		if not interactor.creatureType.canOpenDoors then
			return
		end
		local tile = interactee.doorTile
		if not tile then
			return
		end
		local doorData = tile.doorData
		if not doorData then
			return
		end
		if not info.doneDoorOpenState and self:isDoorBlocked(interactee) then
			-- Disable closing, an entity is in the way
			return
		end
		if doorData.open == info.doneDoorOpenState then
			-- Avoid triggering an event
			return
		end
		doorData.open = info.doneDoorOpenState
		self:broadcastDoorStateChangedEvent(tile, interactor, true)
	end

	interactionTypes.readable = {}
	function interactionTypes.readable:startInfoWorld(interactor, interactionType, interactee)
		return 3
	end
	function interactionTypes.readable:startInfoHeld(interactor, interactionType, interactee)
		return 2
	end
	function interactionTypes.readable:resultWorld(interactor, interactionType, interactee, info)
		if not self.state.player or interactor ~= self.state.player then
			return
		end
		local item = interactionType == "world" and interactee.itemData or interactee
		local name = item.itemType.displayName
		if item.writtenText then
			local text = item.writtenText
			if item.writtenTextStartLineBreak then
				text = "\n" .. text
			end
			self:announce("The " .. name .. " reads: " .. text, "lightGrey")
		else
			self:announce("The " .. name .. " is blank.", "lightGrey")
		end
	end
	interactionTypes.readable.resultHeld = interactionTypes.readable.resultWorld

	interactionTypes.observable = {}
	function interactionTypes.observable:startInfoWorld(interactor, interactionType, interactee)
		return 4
	end
	function interactionTypes.observable:startInfoHeld(interactor, interactionType, interactee)
		return 3
	end
	function interactionTypes.observable:resultWorld(interactor, interactionType, interactee, info)
		if not self.state.player or interactor ~= self.state.player then
			return
		end
		local item = interactionType == "world" and interactee.itemData or interactee
		local name = item.itemType.displayName
		if item.examineDescription then
			local text = item.examineDescription
			self:announce(text, "lightGrey")
		else
			self:announce("The " .. name .. " is nondescript.", "lightGrey")
		end
	end
	interactionTypes.observable.resultHeld = interactionTypes.observable.resultWorld

	interactionTypes.button = {} -- Store state and other information on the item, not an entity representing the item in the world
	function interactionTypes.button:startInfoWorld(interactor, interactionType, interactee)
		return 1
	end
	function interactionTypes.button:resultWorld(interactor, interactionType, interactee, info)
		local item = interactionType == "world" and interactee.itemData or interactee
		if item.pressed or item.frozenState then
			return
		end
		local x, y
		if interactionType == "world" then
			x, y = interactee.x, interactee.y
		elseif interactor then
			x, y = interactor.x, interactor.y
		end
		if item.onPress then
			item.onPress(self, item, x, y)
		end
		item.pressed = true
		self:broadcastButtonStateChangedEvent(item, interactor, true, x, y)
	end
	interactionTypes.button.startInfoHeld = interactionTypes.button.startInfoWorld
	interactionTypes.button.resultHeld = interactionTypes.button.resultWorld

	interactionTypes.lever = {} -- Store state and other information on the item, not an entity representing the item in the world
	function interactionTypes.lever:startInfoWorld(interactor, interactionType, interactee)
		local item = interactionType == "world" and interactee.itemData or interactee
		return 3, {doneState = not item.active}
	end
	function interactionTypes.lever:resultWorld(interactor, interactionType, interactee, info)
		local item = interactionType == "world" and interactee.itemData or interactee
		if item.frozenState then
			return
		end
		if info.doneState == not not item.active then
			return
		end
		local x, y
		if interactionType == "world" then
			x, y = interactee.x, interactee.y
		elseif interactor then
			x, y = interactor.x, interactor.y
		end
		if item.active then
			if item.onDeactivate then
				item.onDeactivate(self, item, x, y)
			end
			item.active = false
		else
			if item.onActivate then
				if item.itemType.onActivateMessage and interactor == self.state.player and self.state.player then
					self:announce(item.itemType.onActivateMessage, "lightGrey")
				end
				item.onActivate(self, item, x, y)
			end
			item.active = true
		end
		self:broadcastLeverStateChangedEvent(item, interactor, true, x, y)
	end
	interactionTypes.lever.startInfoHeld = interactionTypes.lever.startInfoWorld
	interactionTypes.lever.resultHeld = interactionTypes.lever.resultWorld

	interactionTypes.heavyDoor = {}
	function interactionTypes.heavyDoor:startInfoWorld(interactor, interactionType, interactee)
		return 12
	end
	function interactionTypes.heavyDoor:resultWorld(interactor, interactionType, interactee, info)
		if not self.state.player or interactor ~= self.state.player then
			return
		end
		self:announce("The door is too heavy to move.", "lightGrey")
	end

	interactionTypes.healItem = {}
	local function checkHealHasEffect(entity, item)
		local slowBleeding, heal, replenishBlood, refillAir
		if entity.bleedingAmount and entity.bleedingAmount ~= 0 and item.itemType.healItemBleedRateSubtract and (item.itemType.healItemBleedRateSubtract == "all" or item.itemType.healItemBleedRateSubtract > 0) then
			slowBleeding = true
		end
		if entity.health and entity.health < entity.creatureType.maxHealth and item.itemType.healItemHealthAdd and (item.itemType.healItemHealthAdd == "all" or item.itemType.healItemHealthAdd > 0) then
			heal = true
		end
		if entity.blood and entity.blood < entity.creatureType.maxBlood and item.itemType.healItemBloodReplenish and (item.itemType.healItemBloodReplenish == "all" or item.itemType.healItemBloodReplenish > 0) then
			replenishBlood = true
		end
		if entity.drownTimer and entity.drownTimer ~= 0 and item.itemType.healItemAirTimeRefill and (item.itemType.healItemAirTimeRefill == "all" or item.itemType.healItemAirTimeRefill > 0) then
			refillAir = true
		end

		return slowBleeding or heal or replenishBlood or refillAir
	end
	local function doHealEffect(entity, item) -- Returns whether to delete the item
		if entity.bleedingAmount and entity.bleedingAmount ~= 0 and item.itemType.healItemBleedRateSubtract and (item.itemType.healItemBleedRateSubtract == "all" or item.itemType.healItemBleedRateSubtract > 0) then
			entity.bleedingAmount = math.max(0, entity.bleedingAmount - (item.itemType.healItemBleedRateSubtract == "all" and math.huge or item.itemType.healItemBleedRateSubtract))
		end
		if entity.health and entity.health < entity.creatureType.maxHealth and item.itemType.healItemHealthAdd and (item.itemType.healItemHealthAdd == "all" or item.itemType.healItemHealthAdd > 0) then
			entity.health = math.min(entity.creatureType.maxHealth, entity.health + (item.itemType.healItemHealthAdd == "all" and math.huge or item.itemType.healItemHealthAdd))
		end
		if entity.blood and entity.blood < entity.creatureType.maxBlood and item.itemType.healItemBloodReplenish and (item.itemType.healItemBloodReplenish == "all" or item.itemType.healItemBloodReplenish > 0) then
			entity.blood = math.min(entity.creatureType.maxBlood, entity.blood + (item.itemType.healItemBloodReplenish == "all" and math.huge or item.itemType.healItemBloodReplenish))
		end
		if entity.drownTimer and entity.drownTimer ~= 0 and item.itemType.healItemAirTimeRefill and (item.itemType.healItemAirTimeRefill == "all" or item.itemType.healItemAirTimeRefill > 0) then
			entity.drownTimer = math.max(0, entity.drownTimer - (item.itemType.healItemAirTimeRefill == "all" and math.huge or item.itemType.healItemAirTimeRefill))
		end

		if entity == self.state.player and item.itemType.healItemMessage then
			self:announce(item.itemType.healItemMessage, item.itemType.healItemMessageColour or "lightGrey")
		end

		item.healingUsed = not (item.itemType.healItemEndlessUse or item.itemType.healItemDeleteOnUse) -- Don't set the entire stack to used if we're going to delete it, since consumable healing items are allowed to be in stacks
		return item.itemType.healItemDeleteOnUse
	end
	function interactionTypes.healItem:startInfoWorld(interactor, interactionType, interactee)
		if interactee.itemData.itemType.healingRequiresHolding then
			if interactor == self.state.player then
				self:announce("Can only use this item from inventory.", "darkGrey")
			end
			return
		end
		if interactee.itemData.healingUsed then
			if interactor == self.state.player then
				self:announce("The item has already been used.", "darkGrey")
			end
			return
		end
		-- if not checkHealHasEffect(interactor, interactee.itemData) then
		-- 	if interactor == self.state.player then
		-- 		self:announce("It won't have any effect.", "darkGrey")
		-- 	end
		-- 	return
		-- end
		return interactee.itemData.itemType.healItemUseTimerOnGround or interactee.itemData.itemType.healItemUseTimer
	end
	function interactionTypes.healItem:startInfoHeld(interactor, interactionType, interactee)
		if interactee.healingUsed then
			if interactor == self.state.player then
				self:announce("The item has already been used.", "darkGrey")
			end
			return
		end
		-- if not checkHealHasEffect(interactor, interactee) then
		-- 	if interactor == self.state.player then
		-- 		self:announce("It won't have any effect.", "darkGrey")
		-- 	end
		-- 	return
		-- end
		return interactee.itemType.healItemUseTimer
	end
	function interactionTypes.healItem:resultWorld(interactor, interactionType, interactee, info)
		local item = interactionType == "world" and interactee.itemData or interactee
		local delete = doHealEffect(interactor, item)
		if delete then
			return {
				deleteInteractee = true
			}
		end
	end
	interactionTypes.healItem.resultHeld = interactionTypes.healItem.resultWorld

	self.state.interactionTypes = interactionTypes
end

return game
