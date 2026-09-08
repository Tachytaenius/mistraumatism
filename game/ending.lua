local consts = require("consts")
local commands = require("commands")

local game = {}

function game:setReachedSafety()
	self.state.reachedSafety = true
	local player = self.state.player
	if player then
		player.roseRage = false
	end
end

function game:doesPlayerHaveSecretLevelKey()
	local player = self.state.player
	if not player then
		return
	end
	local has = false
	self:tickItems(function(item, x, y, locationType, locationEntity)
		if
			locationEntity == player and
			(locationType == "worn" or locationType == "inventory")
		then
			-- This is an item on the player
			if item.isSecretLevelKey then
				has = true
			end
		end
	end)
	return has
end

function game:toCredits()
	self:setMusic("the-long-view", true)
	self.mode = "text"
	self.textInfo = {
		path = "text/credits-shown.txt",
		timer = 0,
		releaseTime = 5,
		getColour = function(x, y)
			return "white", "black"
		end,
		updateFunction = function(self, dt)
			if commands.checkCommand("confirm") and self.textInfo.timer >= self.textInfo.releaseTime then
				love.event.quit()
				-- TODO: Quick fadeout (visually and audially)
				self.quitting = true
				return true -- As in game/init.lua
			end
			self.textInfo.timer = self.textInfo.timer + dt
		end
	}
end

function game:checkForGameFinished()
	local player = self.state.player
	if not player or player.dead then
		return
	end
	local tile = self:getTile(player.x, player.y)
	if not tile then
		return
	end
	if tile.isGameFinishTrigger then
		self:finishGame()
	end
end

function game:finishGame()
	if self:doesPlayerHaveSecretLevelKey() then
		self:allowLevelAccess(consts.secretLevelName)
		-- TODO: Inform the player that they're getting the secret ending.
		self:announce("It feels like you now even know that you're loved.\nYou have done well ♥", "green")
		self.afterEndingSequence = "secret" -- In this case you view credits when going back to bed in the secret sanctuary
	else
		self.afterEndingSequence = "credits"
	end
	-- In either case, quit game when credits are done.

	self:setReachedSafety()

	self.state.playerEscaping = true
	self.state.playerEscapingCallbacks = {}
	self.state.playerEscapingCallbacks[20] = function()
		self:clearAnnouncements()
	end
	self.state.playerEscapingCallbacks[56] = function()
		self:setMusic("mercious", true, true)
	end
	function self.state.playerEscapingCallbacks.finished()
		self.state.playerEscapeSteps = nil
		self.state.playerEscaping = nil
		self.state.playerEscapingCallbacks = nil
		self:endingTransition()
	end
end

function game:endingTransition()
	self.mode = "text"
	self.textInfo = {
		path = "text/trust-sombre.txt",
		timer = 0,
		releaseTime = 5,
		getColour = function(x, y)
			return "white", "black"
		end,
		updateFunction = function(self, dt)
			if commands.checkCommand("confirm") and self.textInfo.timer >= self.textInfo.releaseTime then
				self:fadeMusicOut(3)
				if self.afterEndingSequence == "secret" then
					self.mode = "gameplay"
					self:changeLevel(consts.secretLevelName)
				elseif self.afterEndingSequence == "credits" then
					self:toCredits()
				else
					error("afterEndingSequence isn't set to a correct value: \"" .. tostring(self.afterEndingSequence) .. "\"")
				end
				return true -- As in game/init.lua
			end
			self.textInfo.timer = self.textInfo.timer + dt
		end
	}
	self.forceRepeatUpdate = true
end

function game:advanceEscape()
	local state = self.state
	local player = state.player
	if not player or player.dead then
		return
	end

	if #player.actions > 0 then
		return
	end

	self.state.playerEscapeSteps = self.state.playerEscapeSteps or 0

	local dir = "up"
	local offsetX, offsetY = self:getDirectionOffset(dir)

	if not self:getWalkable(player.x + offsetX, player.y + offsetY, false, false) then
		if self.state.playerEscapingCallbacks.finished then
			self.state.playerEscapingCallbacks.finished()
		end
		return
	end

	local newAction = self.state.actionTypes.move.construct(self, player, dir)
	if newAction then
		self.state.playerEscapeSteps = self.state.playerEscapeSteps + 1
		if self.state.playerEscapingCallbacks[self.state.playerEscapeSteps] then
			self.state.playerEscapingCallbacks[self.state.playerEscapeSteps]()
		end
		player.actions[#player.actions+1] = newAction
		return -- No further actions
	end
end

return game
