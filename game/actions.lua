local commands = require("commands")
local consts = require("consts")

local game = {}

function game:loadActionTypes()
	local state = self.state
	local actionTypes = {}
	state.actionTypes = actionTypes

	local function newActionType(name)
		local new = {name = name}
		actionTypes[name] = new
		actionTypes[#actionTypes+1] = new
		return new
	end

	-- Within each function, self is the game instance

	local move = newActionType("move")
	function move.construct(self, entity, direction)
		local moveTimerLength = entity.creatureType.moveTimerLength
		if not moveTimerLength then
			return
		end
		local new = {type = "move"}
		new.direction = direction
		local multiplier = self:isDirectionDiagonal(direction) and consts.inverseDiagonal or 1
		new.timer = math.floor(moveTimerLength * multiplier)
		return new
	end
	function move.process(self, entity, action)
		local destinationX, destinationY = self:getDestinationTile(entity)
		if self:getWalkable(destinationX, destinationY) then
			action.timer = action.timer - 1
			if action.timer <= 0 then
				entity.x, entity.y = destinationX, destinationY
				action.doneType = "completed"
				return
			end
		else
			action.doneType = "cancelled"
		end
	end
	function move.fromInput(self, player)
		local playerMoveTimerLength = player.creatureType.moveTimerLength
		if playerMoveTimerLength then
			local direction
			if commands.checkCommand("moveRight") then
				direction = "right"
			elseif commands.checkCommand("moveUpRight") then
				direction = "upRight"
			elseif commands.checkCommand("moveUp") then
				direction = "up"
			elseif commands.checkCommand("moveUpLeft") then
				direction = "upLeft"
			elseif commands.checkCommand("moveLeft") then
				direction = "left"
			elseif commands.checkCommand("moveDownLeft") then
				direction = "downLeft"
			elseif commands.checkCommand("moveDown") then
				direction = "down"
			elseif commands.checkCommand("moveDownRight") then
				direction = "downRight"
			end
			if direction then
				local offsetX, offsetY = self:getDirectionOffset(direction)
				if self:getWalkable(player.x + offsetX, player.y + offsetY) then
					return actionTypes.move.construct(self, player, direction)
				end
			end
		end
	end

	local shoot = newActionType("shoot")
	function shoot.construct(self, entity, targetX, targetY)
		local new = {type = "shoot"}
		new.relativeX = targetX - entity.x
		new.relativeY = targetY - entity.y
		new.timer = 1
		return new
	end
	function shoot.process(self, entity, action)
		if not (entity.heldItem and entity.heldItem.itemType.isGun) then
			action.doneType = "cancelled"
		else
			action.timer = action.timer - 1
			if action.timer <= 0 then
				action.doneType = "completed"
				self:shootGun(entity, action, entity.heldItem)
			end
		end
	end
	function shoot.fromInput(self, player)
		if not commands.checkCommand("shoot") then
			return
		end
		if not (player.heldItem and player.heldItem.itemType.isGun) then
			return
		end
		local cursor = self.state.cursor
		if not cursor then
			return
		end
		return actionTypes.shoot.construct(self, player, cursor.x, cursor.y)
	end
end

return game
