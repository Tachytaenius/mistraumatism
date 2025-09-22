local util = require("util")

local game = {}

function game:announce(text, colour)
	colour = colour or "white"
	local state = self.state
	local announcement = {
		text = text,
		colour = colour,
		tick = state.tick,
		isFirstOfTick = not self.state.announcementMadeThisTick,
		isFirstAfterPlayerControlLost = not self.state.announcementMadeThisTick and self.state.playerLostControlThisTick,
		osTime = os.time()
	}
	state.announcements[#state.announcements+1] = announcement
	self.state.announcementMadeThisTick = true
	-- TODO: Split announcements with word wrap. For now just split at line breaks
	local continuing = false
	for line in util.iterateLines(text) do
		state.splitAnnouncements[#state.splitAnnouncements+1] = {
			text = line,
			announcement = announcement,
			isContinuedLine = continuing
		}
		continuing = true
	end
end

return game
