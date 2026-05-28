local game = {}

-- For flavour text

function game:handlePlayerMessages()
	local state = self.state
	local player = state.player
	if not player then
		return
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

	if not player.readBorageCourageMessage and player.borageCourage then
		player.readBorageCourageMessage = true
		self:announce("You feel a forward sense of determination.", "blue")
	end

	if not player.readRoseRageMessage and player.roseRage then
		player.readRoseRageMessage = true
		self:announce("Your body quakes with a precise anger. Your blood\nclimbs to your head and clamours for its revenge.", "red")
	end
end

return game
