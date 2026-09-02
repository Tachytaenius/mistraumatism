local util = require("util")
local consts = require("consts")
local commands = require("commands")

local game = {}

function game:setInitialNonPersistentVariables()
	local state = self.state
	state.nonPersistentVariablesOn = true

	for _, entity in ipairs(state.entities) do
		if entity.entityType == "creature" then
			self:setCreatureInitNonPersistentVariables(entity)
		end
	end

	state.announcementMadeThisTick = false
end

function game:setCurrentSwimInfo(entity)
	entity.initialDrowning, entity.initialDrowningCause = self:isDrowning(entity)
	entity.initialSubmergedFluid = self:getCurrentLiquid(entity)
end

function game:unsetCurrentSwimInfo(entity)
	entity.initialDrowning, entity.initialDrowningCause = nil, nil
	entity.initialSubmergedFluid = nil
end

function game:setCreatureInitNonPersistentVariables(entity)
	entity.initialHealthThisTick = entity.health
	entity.initialBloodThisTick = entity.blood
	entity.initialDrownTimerThisTick = entity.drownTimer
	entity.initialPsychicDamageThisTick = entity.psychicDamage

	entity.psychicDamageTakenThisTick = nil
	entity.damageTakenThisTick = nil
end

function game:clearNonPersistentVariables()
	local state = self.state
	state.nonPersistentVariablesOn = false

	for _, entity in ipairs(state.entities) do
		if entity.entityType == "creature" then
			entity.initialHealthThisTick = nil
			entity.initialBloodThisTick = nil
			entity.initialDrownTimerThisTick = nil
			entity.initialPsychicDamageThisTick = nil

			entity.psychicDamageTakenThisTick = nil
			entity.damageTakenThisTick = nil
		end
	end

	state.announcementMadeThisTick = nil
end

function game:newTeam(name)
	local state = self.state

	assert(not state.teams[name], "Team with name " .. name .. " already exists")

	state.teams[name] = {relations = {}}
end

local relations = util.arrayToSet({"enemy", "neutral", "friendly"})
function game:setTeamRelation(teamAName, teamBName, relation)
	local state = self.state

	local teamA = state.teams[teamAName]
	local teamB = state.teams[teamBName]
	assert(teamA, "No team with name " .. teamAName)
	assert(teamB, "No team with name " .. teamBName)

	if not relations[relation] then
		error("Invalid team relation " .. relation)
	end
	if relation == "neutral" then
		relation = nil
	end

	teamA.relations[teamB] = relation
	teamB.relations[teamA] = relation
end

function game:getTeamRelation(teamAName, teamBName)
	if not teamAName or not teamBName then
		return "neutral"
	end

	local state = self.state

	local teamA = state.teams[teamAName]
	local teamB = state.teams[teamBName]
	assert(teamA, "No team with name " .. teamAName)
	assert(teamB, "No team with name " .. teamBName)

	if teamA == teamB then
		return "friendly"
	end

	assert(teamA.relations[teamB] == teamB.relations[teamA], "Mismatched relations between " .. teamAName .. " and " .. teamBName)

	return teamA.relations[teamB] or "neutral"
end

function game:getDirection(x, y)
	if x == 1 and y == 0 then
		return "right"
	elseif x == 1 and y == -1 then
		return "upRight"
	elseif x == 0 and y == -1 then
		return "up"
	elseif x == -1 and y == -1 then
		return "upLeft"
	elseif x == -1 and y == 0 then
		return "left"
	elseif x == -1 and y == 1 then
		return "downLeft"
	elseif x == 0 and y == 1 then
		return "down"
	elseif x == 1 and y == 1 then
		return "downRight"
	elseif x == 0 and y == 0 then
		return "zero"
	else
		-- TODO if needed
	end
end

function game:getDirectionOffset(direction)
	if direction == "right" then
		return 1, 0
	elseif direction == "upRight" then
		return 1, -1
	elseif direction == "up" then
		return 0, -1
	elseif direction == "upLeft" then
		return -1, -1
	elseif direction == "left" then
		return -1, 0
	elseif direction == "downLeft" then
		return -1, 1
	elseif direction == "down" then
		return 0, 1
	elseif direction == "downRight" then
		return 1, 1
	elseif direction == "zero" then
		return 0, 0
	else
		error("Unknown direction " .. direction)
	end
end

function game:getDirectionOffsetNormalised(direction)
	local d = consts.diagonal
	if direction == "right" then
		return 1, 0
	elseif direction == "upRight" then
		return d, -d
	elseif direction == "up" then
		return 0, -1
	elseif direction == "upLeft" then
		return -d, -d
	elseif direction == "left" then
		return -1, 0
	elseif direction == "downLeft" then
		return -d, d
	elseif direction == "down" then
		return 0, 1
	elseif direction == "downRight" then
		return d, d
	elseif direction == "zero" then
		error("Can't normalise zero direction")
	else
		error("Unknown direction " .. direction)
	end
end

function game:isDirectionDiagonal(direction)
	if direction == "right" then
		return false
	elseif direction == "upRight" then
		return true
	elseif direction == "up" then
		return false
	elseif direction == "upLeft" then
		return true
	elseif direction == "left" then
		return false
	elseif direction == "downLeft" then
		return true
	elseif direction == "down" then
		return false
	elseif direction == "downRight" then
		return true
	elseif direction == "zero" then
		error("Diagonality doesn't apply to zero direction")
	else
		error("Unknown direction " .. direction)
	end
end

function game:length(x, y)
	return math.sqrt(x ^ 2 + y ^ 2)
end

function game:distance(x1, y1, x2, y2)
	return self:length(x2 - x1, y2 - y1)
end

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
	self:setMusic("the-long-view")
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
		self.afterEndingSequence = "secret" -- In this case you view credits when going back to bed in the secret sanctuary
	else
		self.afterEndingSequence = "credits"
	end
	-- In either case, quit game when credits are done.

	self:clearAnnouncements()
	self:setReachedSafety()
	self:setMusic("mercious", false, true)
	-- TODO: The planned ending!
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

return game
