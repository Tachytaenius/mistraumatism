local util = require("util")

local game = {}

function game:announce(text, colour)
	colour = colour or "white"
	local state = self.state
	local announcement = {text = text, colour = colour, tick = state.tick, osTime = os.time()}
	state.announcements[#state.announcements+1] = announcement
	-- TODO: Split announcements with word wrap. For now just split at line breaks
	for line in util.iterateLines(text) do
		state.splitAnnouncements[#state.splitAnnouncements+1] = {text = line, announcement = announcement}
	end
end

function game:announceDamages()
	local player = self.state.player or self.state.initialPlayerThisTick
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
				if not entity.dead or entity.deathTick == self.state.tick then
					self:announce("You hit the " .. self:getEntityDisplayName(entity) .. " for " .. damage .. " damage.", "cyan")
				else
					self:announce("You hit the dead " .. self:getEntityDisplayName(entity) .. " for " .. damage .. " damage.", "darkGrey")
				end
			end
		end
	end
	for _, entity in ipairs(self.state.fallingEntities) do
		if entity == player then
			self:announce("You have fallen into a pit!", "red")
		end
	end
	if player and player.dead and player.deathTick == self.state.tick then
		self:announce("You have died.", "darkRed")
	end
end

return game
