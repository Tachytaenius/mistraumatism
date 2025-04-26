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
	self.viewportWidth, self.viewportHeight = 40, 40
	self.currentFramebuffer, self.otherFramebuffer = self:newFramebuffer(), self:newFramebuffer()
	self.updateTimer = 0 -- Used when player is not in control, "spent" on fixed updates
	self.realTime = 0

	local state = {}
	self.state = state

	state.tick = 0

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
	self:loadItemTypes()

	state.map = {}
	state.map.width = 128
	state.map.height = 128
	for x = 0, state.map.width - 1 do
		local column = {}
		state.map[x] = column
		for y = 0, state.map.height - 1 do
			local tile = {x = x, y = y}
			tile.type = love.math.random() < 0.005 and "pit" or love.math.random() < 0.1 and "wall" or "floor"
			column[y] = tile
		end
	end

	state.lastPlayerX, state.lastPlayerY, state.lastPlayerSightDistance = 0, 0, 0 -- Failsafes in case of no player

	state.teams = {}
	self:newTeam("player")
	self:newTeam("monster")
	self:setTeamRelation("player", "monster", "enemy")

	state.entities = {}
	state.player = self:newCreatureEntity({
		creatureTypeName = "human",
		team = "player",
		x = 0, y = 0,
		-- heldItem = self:newItemData({
		-- 	itemTypeName = "pistol"
		-- })
	})
	self:newCreatureEntity({
		creatureTypeName = "zombie",
		team = "monster",
		x = 5, y = 5,
		targetEntity = state.player -- TEMP
	})

	state.projectiles = {}

	state.cursor = {x = 0, y = 0}
end

return game
