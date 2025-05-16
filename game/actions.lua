local commands = require("commands")
local consts = require("consts")

local game = {}

function game:loadActionTypes()
	local actionTypes = {}
	self.state.actionTypes = actionTypes

	local function newActionType(name, displayName)
		local new = {name = name}
		assert(displayName, "New action type needs display name")
		new.displayName = displayName
		actionTypes[name] = new
		actionTypes[#actionTypes+1] = new
		return new
	end

	-- Within each function, self is the game instance

	local move = newActionType("move", "move")
	function move.construct(self, entity, direction)
		local moveTimerLength = entity.creatureType.moveTimerLength
		if not moveTimerLength then
			return
		end
		local new = {type = "move"}
		assert(direction ~= "zero", "Move action should not use the zero direction")
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
			if not commands.checkCommand("moveCursor") then
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
			end
			if direction then
				local offsetX, offsetY = self:getDirectionOffset(direction)
				if self:getWalkable(player.x + offsetX, player.y + offsetY) then
					return actionTypes.move.construct(self, player, direction)
				end
			end
		end
	end

	local shoot = newActionType("shoot", "shoot")
	function shoot.construct(self, entity, targetX, targetY, targetEntity)
		local new = {type = "shoot"}
		new.relativeX = targetX - entity.x
		new.relativeY = targetY - entity.y
		new.timer = 1
		new.targetEntity = targetEntity
		return new
	end
	function shoot.process(self, entity, action)
		if not (entity.heldItem and entity.heldItem.itemType.isGun) then
			action.doneType = "cancelled"
		else
			action.timer = action.timer - 1
			if action.timer <= 0 then
				action.doneType = "completed"
				local targetEntity
				if action.targetEntity and action.relativeX + entity.x == action.targetEntity.x and action.relativeY + entity.y == action.targetEntity.y then
					targetEntity = action.targetEntity
				end
				self:shootGun(entity, action, entity.heldItem, targetEntity)
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
		return actionTypes.shoot.construct(self, player, cursor.x, cursor.y, self:getCursorEntity())
	end

	local melee = newActionType("melee", "melee")
	function melee.construct(self, entity, targetEntity, direction)
		if not entity.creatureType.meleeTimerLength then
			return
		end
		if not targetEntity then
			return
		end
		local new = {type = "melee"}
		new.direction = direction
		new.timer = entity.creatureType.meleeTimerLength
		new.targetEntity = targetEntity
		return new
	end
	function melee.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			local ox, oy = self:getDirectionOffset(action.direction)
			local targetX, targetY = entity.x + ox, entity.y + oy
			if entity.creatureType.meleeDamage and action.targetEntity.x == targetX and action.targetEntity.y == targetY then
				self:damageEntity(action.targetEntity, entity.creatureType.meleeDamage, entity)
				action.doneType = "completed"
			else
				action.doneType = "cancelled"
			end
		end
	end
	function melee.fromInput(self, player)
		if not commands.checkCommand("melee") then
			return
		end
		if not player.creatureType.meleeTimerLength then
			return
		end
		local targetEntity = self:getCursorEntity()
		if not targetEntity or targetEntity.entityType ~= "creature" then
			return
		end
		local dx, dy = targetEntity.x - player.x, targetEntity.y - player.y
		if math.abs(dx) > 1 or math.abs(dy) > 1 then
			return
		end
		local direction = self:getDirection(dx, dy)
		if not direction then
			return
		end
		return self.state.actionTypes.melee.construct(self, player, targetEntity, direction)
	end

	local pickUp = newActionType("pickUp", "pick up")
	function pickUp.construct(self, entity, targetEntity)
		if entity.heldItem then
			return
		end
		if entity.x ~= targetEntity.x or entity.y ~= targetEntity.y then
			return
		end
		if not targetEntity then
			return
		end
		if not (targetEntity.entityType == "item" and not targetEntity.itemData.itemType.noPickUp) then
			return
		end
		local new = {type = "pickUp"}
		new.timer = 4
		new.targetEntity = targetEntity
		return new
	end
	function pickUp.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			if not entity.heldItem and action.targetEntity.x == entity.x and action.targetEntity.y == entity.y then
				self:registerPickUp(entity, action.targetEntity)
				action.doneType = "completed"
			else
				action.doneType = "cancelled"
			end
		end
	end
	function pickUp.fromInput(self, player)
		if not (commands.checkCommand("pickUpOrDrop") and not commands.checkCommand("dropMode")) then
			return
		end
		if player.heldItem then
			return
		end
		local targetEntity = self:getCursorEntity()
		if not targetEntity or targetEntity.entityType ~= "item" then
			return
		end
		if not (targetEntity.x == player.x and targetEntity.y == player.y) then
			return
		end
		return self.state.actionTypes.pickUp.construct(self, player, targetEntity)
	end

	local drop = newActionType("drop", "drop")
	function drop.construct(self, entity, direction)
		if not entity.heldItem then
			return
		end
		local new = {type = "drop"}
		new.direction = direction
		new.timer = 1
		return new
	end
	function drop.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			local ox, oy = self:getDirectionOffset(action.direction)
			local targetX, targetY = entity.x + ox, entity.y + oy
			if entity.heldItem and not self:tileBlocksAirMotion(targetX, targetY) then
				self:newItemEntity(targetX, targetY, entity.heldItem)
				entity.heldItem = nil
				action.doneType = "completed"
			else
				action.doneType = "cancelled"
			end
		end
	end
	function drop.fromInput(self, player)
		if not (commands.checkCommand("pickUpOrDrop") and commands.checkCommand("dropMode")) then
			return
		end
		if not player.heldItem then
			return
		end
		if not self.state.cursor then
			return
		end
		local x, y = self.state.cursor.x, self.state.cursor.y
		local dx, dy = x - player.x, y - player.y
		if math.abs(dx) > 1 or math.abs(dy) > 1 then
			return
		end
		local direction = self:getDirection(dx, dy)
		if not direction then
			return
		end
		if self:tileBlocksAirMotion(x, y) then
			return
		end
		return self.state.actionTypes.drop.construct(self, player, direction)
	end
end

return game
