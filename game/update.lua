local consts = require("consts")
local settings = require("settings")
local commands = require("commands")

local game = {}

function game:isPlayerInControl()
	local state = self.state
	local player = state.player
	return not player.moveDirection
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
		self:update(consts.fixedUpdateTickLength)
	end
end

function game:getPlayerInput()
	local state = self.state
	local player = state.player
	if not player then
		return
	end

	local playerSpeed = state.creatureTypes[player.creatureType].speed
	if playerSpeed > 0 then
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
				local multiplier = self:isDirectionDiagonal(direction) and consts.diagonal or 1
				player.moveTimer = 1 / (playerSpeed * multiplier)
			end
		end
	end
end

function game:update(dt)
	local state = self.state

	for _, entity in ipairs(state.entities) do
		if entity.moveDirection then
			local destinationX, destinationY = self:getDestinationTile(entity)
			if self:getWalkable(destinationX, destinationY) then
				entity.moveTimer = entity.moveTimer - dt
				if entity.moveTimer <= 0 then
					entity.x, entity.y = destinationX, destinationY
					entity.moveTimer = nil
					entity.moveDirection = nil
				end
			else
				entity.moveTimer = nil
				entity.moveDirection = nil
			end
		end
	end

	state.time = state.time + dt
end

return game
