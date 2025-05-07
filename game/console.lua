local game = {}

function game:announce(text, colour)
	colour = colour or "white"
	local state = self.state
	local announcement = {text = text, colour = colour, tick = state.tick, osTime = os.time()}
	state.announcements[#state.announcements+1] = announcement
	-- TODO: Split announcements with word wrap
	state.splitAnnouncements[#state.splitAnnouncements+1] = {text = text, announcement = announcement}
end

return game
