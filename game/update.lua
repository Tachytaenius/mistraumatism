local consts = require("consts")
local settings = require("settings")
local commands = require("commands")

local game = {}

function game:isPlayerInControl()
	local state = self.state
	local player = state.player
	return not (player.moveDirection or player.waitTimer)
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

	-- We return after every potential action

	-- Try waiting
	if commands.checkCommand("wait") then
		player.waitTimer = 0.25
		return -- No further actions
	end
	
	-- Try moving
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
				return -- No further actions
			end
		end
	end

	-- Try shooting
	if commands.checkCommand("shoot") and state.cursor then
		local newProjectile = {
			startX = player.x,
			startY = player.y,
			currentX = player.x,
			currentY = player.y,
			targetX = state.cursor.x,
			targetY = state.cursor.y,
			speed = 3,
			tile = "∙",
			colour = "darkGrey",
			moveTimer = 0
		}
		if newProjectile.startX == newProjectile.targetX and newProjectile.startY == newProjectile.targetY then
			-- No trajectory
		else
			local hitscanResult, info = self:hitscan(newProjectile.startX, newProjectile.startY, newProjectile.targetX, newProjectile.targetY)
			local trajectoryOctant
			if hitscanResult then
				-- An octant actually hit the end result, so pick it as the trajectory octant for the projectile
				trajectoryOctant = info.octant
			else
				-- Get the octant of the two which got furthest, if there were two
				if #info.triedHitTiles == 1 then
					trajectoryOctant = info.triedHitTiles[1].octant
				else
					local function getMaxDistance(hitTiles)
						local currentMax = -math.huge -- Works fine if #hitTiles == 0
						-- Probably could just check which has a greater number of hit tiles, or only check the distance of the last one, or whatever
						for _, tile in ipairs(hitTiles) do
							local tileDistance = math.sqrt(tile.localX ^ 2 + tile.localY ^ 2)
							currentMax = math.max(currentMax, tileDistance)
						end
						return currentMax
					end
					if getMaxDistance(info.triedHitTiles[1].hitTiles) >= getMaxDistance(info.triedHitTiles[2].hitTiles) then
						trajectoryOctant = info.triedHitTiles[1].octant
					else
						trajectoryOctant = info.triedHitTiles[2].octant
					end
				end
			end
			newProjectile.trajectoryOctant = trajectoryOctant
		end
		state.projectiles[#state.projectiles+1] = newProjectile
		return -- No further actions
	end
end

function game:update(dt)
	local state = self.state

	self:updateProjectiles(dt)

	for _, entity in ipairs(state.entities) do
		if entity.waitTimer then
			entity.waitTimer = entity.waitTimer - dt
			if entity.waitTimer <= 0 then
				entity.waitTimer = nil
			end
		end

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
