local commands = require("commands")

local game = {}

function game:getCursorEntitySelectionList(forceIncludeEntityInList)
	local state = self.state
	local cursor = state.cursor
	if not cursor then
		return nil
	end
	local list = {}
	for _, entity in ipairs(state.entities) do
		if self:cursorCanSelectEntity(entity, true, entity == forceIncludeEntityInList) then
			list[#list+1] = entity
		end
	end
	return list
end

function game:setCursor(x, y)
	if x and y then
		if self.state.cursor then
			self.state.cursor.x = x
			self.state.cursor.y = y
		else
			self.state.cursor = {x = x, y = y}
		end
	else
		self.state.cursor = nil
	end
end

function game:cursorCanSelectEntity(entity, checkPosition, dontCheckAnythingButPositionAndPlayer)
	local state = self.state
	if not state.player then
		return false
	end
	if entity == state.player then
		return false
	end
	if not dontCheckAnythingButPositionAndPlayer then
		if not self:entityCanSeeEntity(state.player, entity) then
			return false
		end
		if entity.dead then
			return false
		end
	end
	if checkPosition and (not state.cursor or not (state.cursor.x == entity.x and state.cursor.y == entity.y)) then
		return false
	end
	return true
end

function game:getSelectedEntityListIndex(forceIncludeEntityInList)
	if not (self.state.cursor and self.state.cursor.selectedEntity) then
		return
	end
	local list = self:getCursorEntitySelectionList(forceIncludeEntityInList)
	if not list then
		return
	end
	for listI, entity in ipairs(list) do
		if entity == self.state.cursor.selectedEntity then
			return listI
		end
	end
	return nil
end

-- Called after a game tick
function game:autoUpdateCursorEntity()
	local state = self.state
	if not state.cursor then
		return
	end
	if state.cursor.selectedEntity then
		local canSelectSelectedEntity = self:cursorCanSelectEntity(state.cursor.selectedEntity, false)
		if state.cursor.lockedOn then
			if canSelectSelectedEntity then
				self:setCursor(state.cursor.selectedEntity.x, state.cursor.selectedEntity.y)
			else
				self:forceDeselectCursorEntity(self:getSelectedEntityListIndex(state.cursor and state.cursor.selectedEntity))
			end
		else
			if not canSelectSelectedEntity then
				self:forceDeselectCursorEntity(self:getSelectedEntityListIndex(state.cursor and state.cursor.selectedEntity))
			end
		end
	else
		state.cursor.lockedOn = false
	end
	return nil
end

-- Called every realtime update
function game:updateCursor()
	local state = self.state

	if not state.player or state.player.dead then
		self:setCursor()
		return
	end

	if commands.checkCommand("clearCursor") then
		self:setCursor()
	end

	-- From graphics.lua
	local cameraX, cameraY
	if state.player then
		cameraX, cameraY = state.player.x, state.player.y
	else
		cameraX, cameraY = state.lastPlayerX, state.lastPlayerY
	end
	-- Remove cursor if offscreen
	local topLeftX = cameraX - math.floor(self.viewportWidth / 2)
	local topLeftY = cameraY - math.floor(self.viewportHeight / 2)
	if state.cursor then
		local dx, dy = state.cursor.x - topLeftX, state.cursor.y - topLeftY
		if not (
			dx >= 0 and dy >= 0 and
			dx <= self.viewportWidth - 1 and dy <= self.viewportHeight - 1
		) then
			self:setCursor()
		end
	end

	local moved
	local function move(direction)
		moved = true
		if not state.cursor then
			self:setCursor(cameraX, cameraY)
		end -- else
			local ox, oy = self:getDirectionOffset(direction)
			self:setCursor(
				math.max(topLeftX, math.min(topLeftX + self.viewportWidth - 1, state.cursor.x + ox)),
				math.max(topLeftY, math.min(topLeftY + self.viewportHeight - 1, state.cursor.y + oy))
			)
		-- end
	end

	if commands.checkCommand("moveCursor") then
		if not state.cursor then
			move("zero")
		end
		if commands.checkCommand("moveCursorRight") then
			move("right")
		end
		if commands.checkCommand("moveCursorUpRight") then
			move("upRight")
		end
		if commands.checkCommand("moveCursorUp") then
			move("up")
		end
		if commands.checkCommand("moveCursorUpLeft") then
			move("upLeft")
		end
		if commands.checkCommand("moveCursorLeft") then
			move("left")
		end
		if commands.checkCommand("moveCursorDownLeft") then
			move("downLeft")
		end
		if commands.checkCommand("moveCursorDown") then
			move("down")
		end
		if commands.checkCommand("moveCursorDownRight") then
			move("downRight")
		end
	end

	if state.cursor and commands.checkCommand("deselectTarget") then
		self:forceDeselectCursorEntity(nil)
	end

	local entityList = self:getCursorEntitySelectionList()
	if entityList and state.cursor then
		local selectedEntity = self:getCursorEntity()
		local movement = 0
		if commands.checkCommand("scrollListBackwards") then
			movement = movement - 1
		end
		if commands.checkCommand("scrollListForwards") then
			movement = movement + 1
		end
		local justGainedSelection = false
		-- if not selectedEntity and (moved or movement ~= 0 or self:entityListChanged(state.cursor.x, state.cursor.y, "selectable")) then
		if not selectedEntity and (moved or movement ~= 0) then
			selectedEntity = entityList[1]
			state.cursor.selectedEntity = selectedEntity
			state.cursor.lockedOn = false
			justGainedSelection = true
		end
		if selectedEntity and not justGainedSelection then
			local i = self:getSelectedEntityListIndex()
			assert(i, "Selected cursor entity is not in the list of currently selectable entities")
			if movement ~= 0 then
				i = i + movement
				i = (i - 1) % #entityList + 1
				state.cursor.selectedEntity = entityList[i]
				state.cursor.lockedOn = false
			end
			if commands.checkCommand("lockOn") then
				state.cursor.lockedOn = not state.cursor.lockedOn
			end
		end
	elseif state.cursor then
		state.cursor.lockedOn = false
	end
end

function game:getCursorEntity() -- Doesn't return selectedEntity if it shouldn't be selected (e.g. if the entity moved during a tick)
	local state = self.state
	if not state.cursor then
		return nil
	end
	if not state.cursor.selectedEntity then
		return nil
	end
	return self:cursorCanSelectEntity(state.cursor.selectedEntity, true) and state.cursor.selectedEntity or nil
end

function game:forceDeselectCursorEntity(reselectIndex)
	local state = self.state
	if not state.cursor then
		return
	end
	state.cursor.selectedEntity = nil
	state.cursor.lockedOn = false
	if not reselectIndex then
		return
	end
	local entityList = self:getCursorEntitySelectionList()
	if entityList then
		state.cursor.selectedEntity = entityList[math.min(reselectIndex, #entityList)]
	end
end

return game
