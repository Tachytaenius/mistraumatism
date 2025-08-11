local util = require("util")
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

function game:newState(params)
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
	self:loadEventTypes()
	self:loadSoundTypes()

	state.teams = {}
	self:newTeam("person")
	self:newTeam("monster")
	self:newTeam("critter")
	self:setTeamRelation("person", "monster", "enemy")

	state.lastPlayerX, state.lastPlayerY, state.lastPlayerSightDistance, state.initialPlayerThisTick = 0, 0, 0, state.player -- Failsafes in case of no player

	state.projectiles = {}
	state.gibs = {}
	state.particles = {}
	state.entities = {}
	state.airlockData = {}
	local levelGenerationResult = self:generateLevel({levelName = params.startLevelName or consts.startLevelName})
	state.player = self:newCreatureEntity({
		creatureTypeName = "human",
		team = "person",
		x = levelGenerationResult.spawnX, y = levelGenerationResult.spawnY
	})
	if levelGenerationResult.playerBleedRate then
		state.player.bleedingAmount = levelGenerationResult.playerBleedRate
	end
	if levelGenerationResult.playerHealth then
		state.player.health = levelGenerationResult.playerHealth
	end

	state.announcements = {}
	state.splitAnnouncements = {}

	state.incrementEntityDisplaysTimerLength = 1
	state.incrementEntityDisplaysSwitchIndicatorTime = 0.08
	state.incrementEntityDisplaysTimer = state.incrementEntityDisplaysTimerLength

	state.tileEntityLists = self:getTileEntityLists()
	state.previousTileEntityLists = nil
end

function game:getCanvasSize(fontImageWidth, fontImageHeight)
	-- Can pass in font image width and height if making window for the first time (only have an image data, since images require a window)
	if not (fontImageWidth and fontImageHeight) then
		fontImageWidth, fontImageHeight = self.fontImage:getDimensions()
	end
	return self.framebufferWidth * fontImageWidth / consts.fontWidthCharacters, self.framebufferHeight * fontImageHeight / consts.fontHeightCharacters
end

function game:init(args)
	self.framebufferWidth, self.framebufferHeight = 56, 48

	self.viewportWidth, self.viewportHeight = 35, 35

	self.consoleWidth = self.framebufferWidth - 2
	self.consoleHeight = self.framebufferHeight - self.viewportHeight - 3

	self.currentFramebuffer, self.otherFramebuffer = self:newFramebuffer(), self:newFramebuffer()

	self.updateTimer = 0 -- Used when player is not in control, "spent" on fixed updates
	self.realTime = 0
	self.tickTimes = {}

	local fontName, paletteName
	local fontArg, paletteArg = "^--font=", "^--palette="
	for _, arg in ipairs(args) do
		if arg:match(fontArg) then
			fontName = arg:gsub(fontArg, "")
		elseif arg:match(paletteArg) then
			paletteName = arg:gsub(paletteArg, "")
		end
	end
	fontName = fontName or "modifiedKelora"
	paletteName = paletteName or "main"

	local fontLocation = "fonts/" .. fontName .. ".png"
	local fontImageData = love.image.newImageData(fontLocation)
	util.remakeWindow(self:getCanvasSize(fontImageData:getDimensions()))
	self.fontImage = love.graphics.newImage(fontLocation)
	self.paletteImage = love.graphics.newImage("palettes/" .. paletteName .. ".png")
	self.characterQuad = love.graphics.newQuad(0, 0, 1, 1, 1, 1) -- Don't-care values
	self.characterColoursShader = love.graphics.newShader("shaders/characterColours.glsl")

	-- TEMP, change as needed
	local skipIntro, flickerIntro, startLevelName
	for _, arg in ipairs(args) do
		if arg == "--skipIntro" then
			skipIntro = true
		elseif arg == "--enableFlickerIntro" then
			flickerIntro = true
		elseif arg == "--drawTickTimes" then
			self.drawTickTimes = true
		end
		local startLevelArg = "^--startLevel="
		if arg:match(startLevelArg) then
			startLevelName = arg:gsub(startLevelArg, "")
		end
	end

	local function makeState()
		self:newState({
			startLevelName = startLevelName
		})
	end
	if skipIntro then
		makeState()
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
					makeState()
					self.mode = "gameplay"
					return true -- To allow initial realtimeUpdate to fully set up new state
				end
				self.textInfo.timer = self.textInfo.timer + dt

				local stages = {"black", "darkGrey", "lightGrey", "white"}

				-- Too flickery for some
				if flickerIntro then
					function self.textInfo.getColour(x, y)
						local proportion = math.min(1, self.textInfo.timer / self.textInfo.fullTime)
						local proportionMaxBackAmount = 2.5 * (1 - math.max(0, proportion - (1 - proportion) * 0.5 * love.math.noise(x / 10, y / 10, self.textInfo.timer * 0.25))) ^ 2
						local proportionModified = math.max(0, proportion - love.math.random() * proportionMaxBackAmount)
						local stage = proportionModified * (#stages - 1)
						local incrementChance = stage % 1
						local stageInt = math.floor(stage) + (love.math.random() < incrementChance and 1 or 0)
						return stages[stageInt + 1] or "white", "black"
					end
				else
					function self.textInfo.getColour(x, y)
						local proportion = math.min(1, self.textInfo.timer / self.textInfo.fullTime)
						return stages[math.floor(proportion * (#stages - 1)) + 1] or "white", "black"
					end
				end
			end
		}
	end
end

return game
