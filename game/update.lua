local consts = require("consts")
local settings = require("settings")
local commands = require("commands")

local game = {}

function game:isPlayerInControl()
	local state = self.state
	local player = state.player
	return not (player.moveTimer or player.waitTimer)
end

function game:realtimeUpdate(dt)
	if self:isPlayerInControl() then
		self.updateTimer = 0
		self:getPlayerInput()
		return
	end

	self.updateTimer = self.updateTimer + dt
	if self.updateTimer >= consts.fixedUpdateTickLength then -- Not doing multiple
		self.updateTimer = 0
		self:update()
	end
end

function game:getPlayerInput()
	local state = self.state
	local player = state.player
	if not player then
		return
	end

	-- We return after every potential action

	-- Try waiting
	if commands.checkCommand("wait") or commands.checkCommand("waitPrecise") then
		player.waitTimer = 1 -- One tick
		return -- No further actions
	end

	-- Try moving
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
				player.moveDirection = direction
				local multiplier = self:isDirectionDiagonal(direction) and consts.inverseDiagonal or 1
				player.moveTimer = math.floor(playerMoveTimerLength * multiplier)
				return -- No further actions
			end
		end
	end

	-- Try shooting
	if commands.checkCommand("shoot") and state.cursor then
		player.shootInfo = {
			targetX = state.cursor.x,
			targetY = state.cursor.y
		}
		player.waitTimer = 1
		return -- No further actions
	end
end

function game:update()
	local state = self.state
	
	self:setInitialNonPersistentVariables()

	self:updateItems()
	self:updateProjectiles()
	self:updateEntities()

	self:clearNonPersistentVariables()

	state.tick = state.tick + 1
end

return game
