local util = require("util")
util.load()

local game = {}

for _, itemName in ipairs(love.filesystem.getDirectoryItems("game")) do
	if itemName == "init.lua" then
		goto continue
	end
	local module = require("game." .. itemName:gsub("%.lua$", ""))
	for k, v in pairs(module) do
		game[k] = v
	end
	::continue::
end

function game:newState()
	local state = {}
	self.state = state

	state.tick = 0

	state.nextAutotileGroup = 0

	self:loadActionTypes()
	self:loadTileTypes()
	self:loadMaterials()
	self:loadCreatureTypes()
	self:loadItemTypes()

	state.teams = {}
	self:newTeam("player")
	self:newTeam("monster")
	self:setTeamRelation("player", "monster", "enemy")

	state.projectiles = {}

	state.lastPlayerX, state.lastPlayerY, state.lastPlayerSightDistance = 0, 0, 0 -- Failsafes in case of no player

	state.entities = {}
	local levelGenerationResult = self:generateLevel()
	state.player = self:newCreatureEntity({
		creatureTypeName = "human",
		team = "player",
		x = levelGenerationResult.spawnX, y = levelGenerationResult.spawnY
	})

	state.announcements = {}
	state.splitAnnouncements = {}

	state.incrementEntityDisplaysTimerLength = 0.8
	state.incrementEntityDisplaysSwitchIndicatorTime = 0.04
	state.incrementEntityDisplaysTimer = state.incrementEntityDisplaysTimerLength
end

function game:init()
	self.framebufferWidth, self.framebufferHeight = 56, 48

	self.viewportWidth, self.viewportHeight = 35, 35

	self.consoleWidth = self.framebufferWidth - 2
	self.consoleHeight = self.framebufferHeight - self.viewportHeight - 3

	self.currentFramebuffer, self.otherFramebuffer = self:newFramebuffer(), self:newFramebuffer()

	self.updateTimer = 0 -- Used when player is not in control, "spent" on fixed updates
	self.realTime = 0

	self:newState()

	self.state.tileEntityLists = self:getTileEntityLists()
	self.state.previousTileEntityLists = nil
end

return game
