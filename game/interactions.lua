local game = {}

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
		if not info.doneDoorOpenState then
			-- Disable closing if an entity is in the way
			for _, entity in ipairs(self.state.entities) do
				if entity.x == interactee.x and entity.y == interactee.y and entity ~= interactee then
					return
				end
			end
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

	self.state.interactionTypes = interactionTypes
end

return game
