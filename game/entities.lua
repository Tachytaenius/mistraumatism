local game = {}

function game:getDestinationTile(entity)
	if not entity.moveDirection then
		return nil
	end
	local offsetX, offsetY = self:getDirectionOffset(entity.moveDirection)
	return entity.x + offsetX, entity.y + offsetY
end

return game
