local util = require("util")

local game = {}

function game:clearAnnouncements()
	local state = self.state
	if not state then
		return
	end
	state.announcements = {}
	state.splitAnnouncements = {}
	state.unreadAnnouncements = {}
	state.unreadAnnouncementsWarn = false
	state.linesSincePlayerInControl = 0
end

function game:announce(text, colour)
	colour = colour or "white"
	local state = self.state
	local announcement = {
		text = text,
		colour = colour,
		tick = state.tick,
		isFirstOfTick = not self.state.announcementMadeThisTick,
		isFirstAfterPlayerControlLost = not self.state.announcementMadeThisTick and self.state.playerLostControlThisTick,
		osTime = os.time(),
		splits = {}
	}
	table.insert(state.announcements, announcement)
	local doProgressUnread = not (not state.player or state.player.dead)
	if doProgressUnread then
		state.unreadAnnouncements[announcement] = true
	end
	self.state.announcementMadeThisTick = true

	local continuing = false
	for line in util.iterateLines(text) do
		local split = {
			text = line,
			announcement = announcement,
			isContinuedLine = continuing,
			read = false
		}
		table.insert(state.splitAnnouncements, split)
		table.insert(announcement.splits, split)
		if doProgressUnread then
			state.linesSincePlayerInControl = state.linesSincePlayerInControl + 1
		end
		continuing = true
	end
end

function game:checkAnnouncementRead(announcement)
	if not self.state.unreadAnnouncements[announcement] then
		return
	end
	for _, split in ipairs(announcement.splits) do
		if not split.read then
			return
		end
	end
	self.state.unreadAnnouncements[announcement] = nil
end

function game:updateAnnouncements()
	local state = self.state

	local rows = 0
	for i = #state.splitAnnouncements, 1, -1 do
		local split = state.splitAnnouncements[i]
		split.read = true
		self:checkAnnouncementRead(split.announcement)

		rows = rows + 1
		local consoleHeight = self.state.consoleHistoryMode and self.framebufferHeight - 2 or self.consoleHeight
		if rows >= consoleHeight then
			break
		end
	end

	if state.linesSincePlayerInControl > 0 then
		state.linesPrintedIndicator = not state.linesPrintedIndicator
	end
	state.linesSincePlayerInControl = 0
	state.unreadAnnouncementsWarn = not util.isEmpty(state.unreadAnnouncements)
end

return game
