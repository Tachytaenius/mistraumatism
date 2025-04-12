local util = require("util")

local game = {}

function game:getDestinationTile(entity)
	if not entity.moveDirection then
		return nil
	end
	local offsetX, offsetY = self:getDirectionOffset(entity.moveDirection)
	return entity.x + offsetX, entity.y + offsetY
end

local uncopiedParameters = util.arrayToSet({

})
function game:newCreatureEntity(parameters)
	local state = self.state

	local new = {}
	for k, v in pairs(parameters) do
		if not uncopiedParameters[k] then
			new[k] = v
		end
	end

	local creatureType = state.creatureTypes[parameters.creatureType]
	new.type = creatureType

	new.health = creatureType.maxHealth
	new.blood = creatureType.maxBlood

	state.entities[#state.entities+1] = new
	return new
end

return game
