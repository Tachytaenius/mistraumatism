local util = require("util")

local game = {}

function game:getDestinationTile(entity)
	local action
	for _, listAction in ipairs(entity.actions) do
		if listAction.type == "move" then
			action = listAction
			break
		end
	end
	if not action then
		return nil
	end
	local offsetX, offsetY = self:getDirectionOffset(action.direction)
	return entity.x + offsetX, entity.y + offsetY
end

function game:loadCreatureTypes()
	local state = self.state
	local creatureTypes = {}
	state.creatureTypes = creatureTypes

	creatureTypes.human = {
		tile = "@",
		colour = "white",
		bloodMaterialName = "bloodRed",

		moveTimerLength = 6,
		sightDistance = 20,
		maxHealth = 14,
		maxBlood = 14
	}

	creatureTypes.zombie = {
		tile = "z",
		colour = "lightGrey",
		bloodMaterialName = "bloodRed",

		moveTimerLength = 12,
		sightDistance = 10,
		maxHealth = 6,
		maxBlood = 7
	}
end

local uncopiedParameters = util.arrayToSet({
	"creatureTypeName"
})
function game:newCreatureEntity(parameters)
	local state = self.state

	local new = {}
	for k, v in pairs(parameters) do
		if not uncopiedParameters[k] then
			new[k] = v
		end
	end

	new.entityType = "creature"
	local creatureType = state.creatureTypes[parameters.creatureTypeName]
	new.creatureType = creatureType

	new.health = creatureType.maxHealth
	new.blood = creatureType.maxBlood
	new.dead = false
	new.actions = {}

	state.entities[#state.entities+1] = new
	return new
end

function game:updateEntitiesAndProjectiles()
	local state = self.state

	local function processActions(actionTypeName)
		local processFunction = state.actionTypes[actionTypeName].process
		for _, entity in ipairs(state.entities) do
			if entity.entityType ~= "creature" or entity.dead then
				goto continue
			end
			local i = 1
			while i <= #entity.actions do
				local action = entity.actions[i]
				local removed = false
				if action.type == actionTypeName then
					processFunction(self, entity, action)
					if action.doneType then
						table.remove(entity.actions, i)
						removed = true
					end
				end
				if not removed then
					i = i + 1
				end
			end
		    ::continue::
		end
	end

	-- Creatures
	local creaturesToRemove = {}
	local function kill(entity)
		entity.dead = true
		entity.actions = {}
		-- creaturesToRemove[entity] = true
	end

	-- AI (player input already happened)
	for _, entity in ipairs(state.entities) do
		if #entity.actions > 0 or entity == state.player then
			goto continue
		end
		if not entity.entityType == "creature" or entity.dead then
			goto continue
		end
		self:getAIActions(entity)
	    ::continue::
	end

	-- Actions (and other things)
	processActions("shoot")
	self:updateProjectiles()
	processActions("move")

	-- Damage and bleeding
	for _, entity in ipairs(state.entities) do
		if entity.entityType ~= "creature" then
			goto continue
		end
		if entity.blood then -- Bleed even if dead
			local lossPerSpatter = 8
			local sameTileSpatterThreshold = 4

			local bloodLoss = math.max(0, entity.initialBloodThisTick - entity.blood)
			if bloodLoss > 0 then
				local bloodRemaining = bloodLoss
				while bloodRemaining > 0 do
					local lossThisSpatter
					local forceSameTile = false
					if bloodRemaining == bloodLoss then
						-- First lot, make it lose 1 and be on the same tile
						lossThisSpatter = 1
						forceSameTile = true
					else
						lossThisSpatter = math.min(bloodRemaining, lossPerSpatter)
					end
					bloodRemaining = bloodRemaining - lossThisSpatter
					local x, y
					if forceSameTile or lossThisSpatter < sameTileSpatterThreshold then
						x, y = entity.x, entity.y
					else
						local minX = math.max(0, entity.x - 1)
						local maxX = math.min(state.map.width - 1, entity.x + 1)

						local minY = math.max(0, entity.y - 1)
						local maxY = math.min(state.map.height - 1, entity.y + 1)

						x = love.math.random(minX, maxX)
						y = love.math.random(minY, maxY)
					end
					self:addSpatter(x, y, entity.creatureType.bloodMaterialName, lossThisSpatter)
				end
			end
		end
		if not entity.dead then
			if entity.health <= 0 or (entity.blood and entity.blood <= 0) then
				kill(entity)
			end
		end
	    ::continue::
	end

	-- Entity removal
	local i = 1
	while i <= #state.entities do
		local entity = state.entities[i]
		if creaturesToRemove[entity] then
			table.remove(state.entities, i)
			if entity == state.player then
				state.player = nil
			end
		else
			i = i + 1
		end
	end
end

return game
