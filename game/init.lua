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
	self.viewportWidth, self.viewportHeight = 32, 32
	self.currentFramebuffer, self.otherFramebuffer = self:newFramebuffer(), self:newFramebuffer()
	self.updateTimer = 0 -- Used when player is not in control, "spent" on fixed updates

	local state = {}
	self.state = state

	state.time = 0

	state.tileTypes = {
		wall = {solidity = "solid", character = "O", boxDrawingNumber = 2, blocksLight = true},
		floor = {solidity = "passable", character = "+"},
		pit = {solidity = "fall", character = "·", ignoreSpatter = true, darkenColour = true}
	}

	state.materials = {}
	local function addMaterial(name, displayName, colour, matterState)
		state.materials[name] = {
			displayName = displayName,
			colour = colour,
			matterState = matterState
		}
	end
	addMaterial("bloodRed", "blood", "darkRed", "liquid")
	addMaterial("bone", "bone", "white", "solid")

	self:loadCreatureTypes()

	state.map = {}
	state.map.width = 128
	state.map.height = 128
	for x = 0, state.map.width - 1 do
		local column = {}
		state.map[x] = column
		for y = 0, state.map.height - 1 do
			local tile = {}
			tile.type = love.math.random() < 0.005 and "pit" or love.math.random() < 0.1 and "wall" or "floor"
			column[y] = tile
		end
	end

	state.entities = {}
	state.player = self:newCreatureEntity({
		creatureType = "human",
		x = 0, y = 0
	})
end

return game
