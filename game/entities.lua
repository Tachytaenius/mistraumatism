local util = require("util")

local game = {}

function game:getDestinationTile(entity)
	if not entity.moveDirection then
		return nil
	end
	local offsetX, offsetY = self:getDirectionOffset(entity.moveDirection)
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
		maxHealth = 14, -- I was gonna make a whole complicated gore system using graph theory for body parts and stuff
		maxBlood = 14
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

	state.entities[#state.entities+1] = new
	return new
end

function game:updateEntities()
	local state = self.state

	-- Creatures
	local creaturesToRemove = {}
	for _, entity in ipairs(state.entities) do
		local function kill()
			-- TODO: Add a corpse item
			creaturesToRemove[entity] = true
		end

		if entity.entityType ~= "creature" then
			goto continue
		end
		if entity.waitTimer then
			entity.waitTimer = entity.waitTimer - 1
			if entity.waitTimer <= 0 then
				entity.waitTimer = nil
			end
		end

		if entity.moveDirection then
			local destinationX, destinationY = self:getDestinationTile(entity)
			if self:getWalkable(destinationX, destinationY) then
				entity.moveTimer = entity.moveTimer - 1
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

		if entity.blood then
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

		if entity.health <= 0 or (entity.blood and entity.blood <= 0) then
			kill()
		end

	    ::continue::
	end
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
