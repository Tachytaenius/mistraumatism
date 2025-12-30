local game = {}

-- For flavour text

function game:handlePlayerMessages()
	local state = self.state
	local player = state.player
	if not player then
		return false
	end

	if not player.hasHeldGun then
		for _, item in ipairs(self:getAllInventoryItems(player)) do
			if item.itemType.isGun then
				player.hasHeldGun = true
				self:announce("The gun feels cold and cruel in your hands. Your\nheart rate rises with an unsteady apprehension.", "lightGrey")
				break
			end
		end
	end
end

return game
