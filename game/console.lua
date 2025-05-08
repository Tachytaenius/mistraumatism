local game = {}

function game:announce(text, colour)
	colour = colour or "white"
	local state = self.state
	local announcement = {text = text, colour = colour, tick = state.tick, osTime = os.time()}
	state.announcements[#state.announcements+1] = announcement
	-- TODO: Split announcements with word wrap
	state.splitAnnouncements[#state.splitAnnouncements+1] = {text = text, announcement = announcement}
end

function game:announceDamages()
	local player = self.state.player
	for _, source in ipairs(self.state.damagesThisTick) do
		local sourceEntity = source.sourceEntity
		for _, destination in ipairs(source) do
			local entity = destination.entity
			local damage = destination.total
			if entity == player and sourceEntity == player then
				self:announce("You hit yourself for " .. damage .. " damage!", "red")
			elseif entity == player then
				self:announce("The " .. self:getEntityDisplayName(sourceEntity) .. " hits you for " .. damage .. " damage!", "red")
			elseif sourceEntity == player then
				self:announce("You hit the " .. self:getEntityDisplayName(entity) .. " for " .. damage .. " damage.", "cyan")
			end
		end
	end
end

return game
