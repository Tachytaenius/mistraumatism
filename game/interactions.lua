local game = {}

function game:isDoorBlocked(doorEntity)
	for _, entity in ipairs(self.state.entities) do
		if entity.x == doorEntity.x and entity.y == doorEntity.y and entity ~= doorEntity then
			return true
		end
	end
	return false
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
		doorData.open = info.doneDoorOpenState
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
		if item.onPress then
			local x, y
			if interactionType == "world" then
				x, y = interactee.x, interactee.y
			elseif interactor then
				x, y = interactor.x, interactor.y
			end
			item.onPress(self, item, x, y)
		end
		item.pressed = true
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
		if item.active then
			if item.onDeactivate then
				local x, y
				if interactionType == "world" then
					x, y = interactee.x, interactee.y
				elseif interactor then
					x, y = interactor.x, interactor.y
				end
				item.onDeactivate(self, item, x, y)
			end
			item.active = false
		else
			if item.onActivate then
				if item.itemType.onActivateMessage and interactor == self.state.player and self.state.player then
					self:announce(item.itemType.onActivateMessage, "lightGrey")
				end
				local x, y
				if interactionType == "world" then
					x, y = interactee.x, interactee.y
				elseif interactor then
					x, y = interactor.x, interactor.y
				end
				item.onActivate(self, item, x, y)
			end
			item.active = true
		end
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

	self.state.interactionTypes = interactionTypes
end

return game
