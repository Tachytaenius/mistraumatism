local consts = require("consts")
local commands = require("commands")

local game = {}

function game:isPlayerInControl()
	local state = self.state
	local player = state.player
	if not player or state.waiting or player.dead then
		return false
	end
	return #player.actions == 0
end

function game:realtimeUpdate(dt)
	if not self.state.player then
		return
	end

	if self:isPlayerInControl() then
		self.updateTimer = 0
		local result = self:getPlayerInput()
		if result and result.wait then
			self.state.waiting = true
		else
			return
		end
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
	if not player or player.dead then
		return
	end

	-- Try waiting
	if commands.checkCommand("wait") or commands.checkCommand("waitPrecise") then
		return {wait = true} -- No further actions
	end

	-- Try making an action
	for _, actionType in ipairs(state.actionTypes) do
		local newAction = actionType.fromInput(self, player)
		if newAction then
			player.actions[#player.actions+1] = newAction
			return -- No further actions
		end
	end
end

function game:update()
	local state = self.state
	state.waiting = false -- No longer needed

	self:setInitialNonPersistentVariables()
	self:updateEntitiesAndProjectiles()
	self:clearNonPersistentVariables()

	if state.player then
		state.lastPlayerX, state.lastPlayerY, state.lastPlayerSightDistance = state.player.x, state.player.y, state.player.creatureType.sightDistance
	end

	state.tick = state.tick + 1
end

return game
