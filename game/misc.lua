local util = require("util")
local consts = require("consts")

local game = {}

function game:setInitialNonPersistentVariables()
	local state = self.state

	for _, entity in ipairs(state.entities) do
		entity.initialHealthThisTick = entity.health
		entity.initialBloodThisTick = entity.blood
	end
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

	assert(teamA.relations[teamB] == teamB.relations[teamA], "Mismatched relations between " .. teamAName .. " and " .. teamBName)

	return teamA.relations[teamB]
end

function game:clearNonPersistentVariables()
	local state = self.state

	for _, entity in ipairs(state.entities) do
		entity.initialHealthThisTick = nil
		entity.initialBloodThisTick = nil
	end
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

return game
