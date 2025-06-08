local util = require("util")
util.load()
local consts = require("consts")
local commands = require("commands")

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
	self:loadInteractionTypes()
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

	state.tileEntityLists = self:getTileEntityLists()
	state.previousTileEntityLists = nil
end

function game:init(args)
	self.framebufferWidth, self.framebufferHeight = 56, 48

	self.viewportWidth, self.viewportHeight = 35, 35

	self.consoleWidth = self.framebufferWidth - 2
	self.consoleHeight = self.framebufferHeight - self.viewportHeight - 3

	self.currentFramebuffer, self.otherFramebuffer = self:newFramebuffer(), self:newFramebuffer()

	self.updateTimer = 0 -- Used when player is not in control, "spent" on fixed updates
	self.realTime = 0

	local fontLocation = "fonts/modifiedKelora.png"
	local fontImageData = love.image.newImageData(fontLocation)
	local characterWidth = fontImageData:getWidth() / consts.fontWidthCharacters
	local characterHeight = fontImageData:getHeight() / consts.fontHeightCharacters
	util.remakeWindow(game, characterWidth, characterHeight)
	self.fontImage = love.graphics.newImage(fontLocation)
	self.paletteImage = love.graphics.newImage("palettes/main.png")
	self.characterQuad = love.graphics.newQuad(0, 0, 1, 1, 1, 1) -- Don't-care values
	self.characterColoursShader = love.graphics.newShader("shaders/characterColours.glsl")

	if args[1] == "skipIntro" then -- TEMP, change as needed
		self:newState()
		self.mode = "gameplay"
	else
		self.mode = "text"
		self.textInfo = {
			path = "text/and-in-mistraumatism.txt",
			timer = 0,
			fullTime = 5,
			releaseTime = 5,
			updateFunction = function(self, dt)
				if commands.checkCommand("confirm") and self.textInfo.timer >= self.textInfo.releaseTime then
					self.updateFunction = nil
					self:newState()
					self.mode = "gameplay"
					return true -- To allow initial realtimeUpdate to fully set up new state
				end
				self.textInfo.timer = self.textInfo.timer + dt

				local stages = {"black", "darkGrey", "lightGrey", "white"}

				-- Too flickery for some
				-- function self.textInfo.getColour(x, y)
				-- 	local proportion = math.min(1, self.textInfo.timer / self.textInfo.fullTime)
				-- 	local proportionMaxBackAmount = 2.5 * (1 - math.max(0, proportion - (1 - proportion) * 0.5 * love.math.perlinNoise(x / 10, y / 10, self.textInfo.timer * 0.25))) ^ 2
				-- 	local proportionModified = math.max(0, proportion - love.math.random() * proportionMaxBackAmount)
				-- 	local stage = proportionModified * (#stages - 1)
				-- 	local incrementChance = stage % 1
				-- 	local stageInt = math.floor(stage) + (love.math.random() < incrementChance and 1 or 0)
				-- 	return stages[stageInt + 1] or "white", "black"
				-- end

				function self.textInfo.getColour(x, y)
					local proportion = math.min(1, self.textInfo.timer / self.textInfo.fullTime)
					return stages[math.floor(proportion * (#stages - 1)) + 1] or "white", "black"
				end
			end
		}
	end
end

return game
