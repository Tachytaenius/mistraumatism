local consts = require("consts")
local commands = require("commands")

local game = {}

function game:isPlayerInControl()
	local state = self.state
	local player = state.player
	if not player or state.waiting or player.dead or self:checkWillFall(state.player) then
		return false
	end
	return #player.actions == 0
end

function game:realtimeUpdate(dt)
	if self.mode == "gameplay" then
		local function inner()
			if not self.state.player or self.state.player.dead then
				self:setCursor()
			end

			if not (self.state.player or self.state.lastPlayerX) and self.state.lastPlayerY then
				return
			end

			if self:isPlayerInControl() then
				self.state.playerWasInControl = true
				self:updateCursor()
				self.updateTimer = 0
				local result = self:getPlayerInput()
				if result and result.wait then
					self.state.waiting = true
				else
					return
				end
			end

			local run = false
			if self.fastForward then
				run = true
			else
				self.updateTimer = self.updateTimer + dt
				run = self.updateTimer >= consts.fixedUpdateTickLength
			end
			if run then
				self.updateTimer = 0

				local startTime = love.timer.getTime()
				self.state.playerLostControlThisTick = self.state.playerWasInControl
				self.state.playerWasInControl = false
				self:update()
				local endTime = love.timer.getTime()
				local tickTime = endTime - startTime
				if #self.tickTimes >= math.floor(self.framebufferWidth / 4) then
					table.remove(self.tickTimes, 1)
				end
				self.tickTimes[#self.tickTimes+1] = tickTime

				self:autoUpdateCursorEntity()
			end
		end
		inner() -- Didn't want to refactor around the returns
		self:updateEntitiesToDraw(dt)
	elseif self.mode == "text" then
		if not self.textInfo.text then
			local text = love.filesystem.read(self.textInfo.path)
			text = text:gsub("—", "─") -- Em dash to single-line horizontal box drawing
			self.textInfo.text = text
		end
		return self.textInfo.updateFunction(self, dt)
	elseif self.mode == "title" then
		return self:updateTitle(dt)
	end
	self.realTime = self.realTime + dt
end

function game:getPlayerInput()
	local state = self.state
	local player = state.player
	if not player or player.dead then
		return
	end

	-- Try waiting
	if commands.checkCommand("wait") or commands.checkCommand("waitPrecise") then
		return {wait = true} -- No further actions
	end

	-- Try making an action
	for _, actionType in ipairs(state.actionTypes) do
		if not actionType.fromInput then
			goto continue
		end
		local newAction = actionType.fromInput(self, player)
		if newAction then
			player.actions[#player.actions+1] = newAction
			return -- No further actions
		end
	    ::continue::
	end
end

function game:update()
	local state = self.state
	state.waiting = false -- No longer needed

	if state.changeToLevelTimer then
		state.changeToLevelTimer = state.changeToLevelTimer - 1
		if state.changeToLevelTimer <= 0 then
			state.changeToLevelTimer = nil
			self:changeLevel(state.changeToLevel)
			state.changeToLevel = nil

			state.startLevelTimer = consts.startLevelTimerLength
		end
		return
	elseif state.startLevelTimer then
		state.startLevelTimer = state.startLevelTimer - 1
		if state.startLevelTimer <= 0 then
			state.startLevelTimer = nil
		end
		return
	end

	state.damagesQueue = state.damagesQueue or {}
	state.eventsQueue = state.eventsQueue or {}

	self:setInitialNonPersistentVariables()

	self:debugOnTick()

	self:tickGibs()
	self:tickParticles()
	self:updateEntitiesAndProjectiles() -- Resets damages queue
	self:diminishExplosions()
	self:dropSpatters()
	self:checkTileMessages()
	self:handleEventsQueue() -- Resets events queue

	self:clearNonPersistentVariables()

	if state.player then
		state.lastPlayerX, state.lastPlayerY, state.lastPlayerSightDistance = state.player.x, state.player.y, state.player.creatureType.sightDistance
		state.playerBeforeRemoval = state.player
	end

	self.state.previousTileEntityLists, self.state.tileEntityLists = self.state.tileEntityLists, nil
	self.state.tileEntityLists = self:getTileEntityLists()

	state.tick = state.tick + 1
end

function game:changeLevel(levelName)
	local state = self.state
	self:handleEventsQueue()
	self:prepareForLevel()
	local levelGenerationResult = self:generateLevel({levelName = levelName})
	if state.player then
		state.player.x = levelGenerationResult.spawnX
		state.player.y = levelGenerationResult.spawnY
	end
	if levelGenerationResult.postLevelGen then
		levelGenerationResult.postLevelGen()
	end
	state.entities[#state.entities+1] = state.player
	self:resetTileEntityLists()
end

return game
