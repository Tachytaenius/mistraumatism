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

function game:init()
	self.framebufferWidth, self.framebufferHeight = 56, 48
	self.currentFramebuffer, self.otherFramebuffer = self:newFramebuffer(), self:newFramebuffer()
	self.updateTimer = 0 -- Used when player is not in control, "spent" on fixed updates

	local state = {}
	self.state = state

	state.time = 0

	state.map = {}
	state.map.width = 128
	state.map.height = 128
	for x = 0, state.map.width - 1 do
		local column = {}
		state.map[x] = column
		for y = 0, state.map.height - 1 do
			local tile = {}
			tile.type = love.math.random() < 0.05 and "pit" or love.math.random() < 0.5 and "wall" or "floor"
			column[y] = tile
		end
	end

	state.entities = {}
	state.player = {}
	state.player.x = 0
	state.player.y = 0
	state.player.speed = 8
	state.entities[#state.entities+1] = state.player
end

return game
