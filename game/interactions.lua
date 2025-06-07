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
	function interactionTypes.door:startInfo(interactor, interactee)
		local timerLength = 7
		local doorData = getDoorTileDoorData(interactee)
		local info = {
			doneDoorOpenState = doorData and not doorData.open
		}
		return timerLength, info
	end
	function interactionTypes.door:result(interactor, interactee, info)
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

	self.state.interactionTypes = interactionTypes
end

return game
