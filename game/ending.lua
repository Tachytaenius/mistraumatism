local consts = require("consts")
local commands = require("commands")
local settings = require("settings")

local game = {}

function game:setReachedSafety()
	self:setIcon("icons/safe.png")
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
	if self.state.gameFinishTriggerTripped then
		return
	end
	self.state.gameFinishTriggerTripped = true
	self:setCursor()
	if self:doesPlayerHaveSecretLevelKey() then
		self:allowLevelAccess(consts.secretLevelName)
		self:announce("It feels like you can now know that you're loved.\nYou have done well ♥", "green")
		self.afterEndingSequence = "secret" -- In this case you view credits when going back to bed in the secret sanctuary
	else
		self.afterEndingSequence = "credits"
	end
	-- In either case, quit game when credits are done.

	self:setReachedSafety()

	self.state.playerEscaping = true
	self.state.playerEscapingCallbacks = {}
	self.state.playerEscapingCallbacks[53] = function()
		self:setMusic("mercious", true, true)
	end
	self.state.playerEscapingCallbacks[60] = function()
		self.endingSequenceGraphics = {
			startY = self.state.player and self.state.player.y or self.state.lastPlayerY,
			endY = 30,
			stage = 1,
			show = function()
				return not self.menuInfo
			end,
			fade = 0,
			realtimeUpdate = function(dt)
				if self.endingSequenceGraphics.stage == 2 then
					self:updateEndScene(dt)
				end
			end,
			update = function()
				if self.endingSequenceGraphics.stage == 1 then
					local y = self.state.player and self.state.player.y or self.state.lastPlayerY
					self.endingSequenceGraphics.fade = math.max(0, math.min(1, 1 - (y - self.endingSequenceGraphics.endY) / (self.endingSequenceGraphics.startY - self.endingSequenceGraphics.endY)))
					if self.endingSequenceGraphics.fade >= 1 then
						self.endingSequenceGraphics.stage = 2
						self.state.playerEscapeSteps = nil

						self.state.playerEscaping = nil
						self.state.playerEscapingCallbacks = nil
						self.mode = "ending"
						self:initEndScene()
					end
				elseif self.endingSequenceGraphics.stage == 2 then
					
				end
			end,
			draw = function()
				local g = self.endingSequenceGraphics
				if g.stage == 2 then
					self:drawEndScene()
					return
				end
				love.graphics.setCanvas(g.canvas)
				love.graphics.clear(1, 1, 1, 1) -- Because this canvas would be remade if font was changed during gameplay, don't rely on this not being cleared if this line isn't here
				love.graphics.setCanvas()
			end
		}
		self:refreshEndGraphicsCanvasses()
	end
end

function game:finishEnding()
	self.endingSequenceGraphics = nil
	if self.state.player and self.state.player.bleedingAmount then
		self.state.player.bleedingAmount = 0
	end
	self:fadeMusicOut(3)
	if self.afterEndingSequence == "secret" then
		self.mode = "gameplay"
		self:changeLevel(consts.secretLevelName)
	elseif self.afterEndingSequence == "credits" then
		self:toCredits()
	else
		error("afterEndingSequence isn't set to a correct value: \"" .. tostring(self.afterEndingSequence) .. "\"")
	end
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

function game:initEndScene()
	local g = self.endingSequenceGraphics
	g.fadeTimer2 = 0
	g.objects = {}
	table.insert(g.objects, {x = 0, y = 30, r = 20})
end

function game:updateEndScene(dt)
	local g = self.endingSequenceGraphics
	g.fadeTimer2 = math.min(1, g.fadeTimer2 + dt * 0.25)
end

function game:drawEndScene()
	local g = self.endingSequenceGraphics
	love.graphics.setCanvas(g.canvas)
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.print("Ending sequence is TODO")

	love.graphics.setColor(1, 1, 1, 1 - g.fadeTimer2)
	love.graphics.rectangle("fill", 0, 0, g.canvas:getDimensions())
	love.graphics.setColor(1, 1, 1)
	love.graphics.setCanvas()
end

function game:refreshEndGraphicsCanvasses()
	local g = self.endingSequenceGraphics
	local w, h = self:getCanvasSize()
	w = w * settings.graphics.canvasScale
	h = h * settings.graphics.canvasScale
	g.canvas = love.graphics.newCanvas(w, h)
end

return game
