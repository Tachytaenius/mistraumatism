-- love entrypoint

local game = require("game") -- util loaded in here

local consts = require("consts")
local util = require("util")
local commands = require("commands")

local fontImage, characterQuad, characterColoursShader, paletteImage

function love.load()
	game:init()
	local fontLocation = "fonts/modifiedKelora.png"
	local fontImageData = love.image.newImageData(fontLocation)
	local characterWidth = fontImageData:getWidth() / consts.fontWidthCharacters
	local characterHeight = fontImageData:getHeight() / consts.fontHeightCharacters
	util.remakeWindow(game, characterWidth, characterHeight)

	fontImage = love.graphics.newImage(fontLocation)
	paletteImage = love.graphics.newImage("palettes/main.png")
	characterQuad = love.graphics.newQuad(0, 0, 1, 1, 1, 1) -- Don't-care values
	characterColoursShader = love.graphics.newShader("shaders/characterColours.glsl")
end

function love.keypressed(key)
	commands.keyPressed(key)
end

function love.update(dt)
	game:realtimeUpdate(dt)
	game.realTime = game.realTime + dt
	commands.tickFinished()
end

function love.draw()
	game:draw()
	local characterWidth = fontImage:getWidth() / consts.fontWidthCharacters
	local characterHeight = fontImage:getHeight() / consts.fontHeightCharacters
	love.graphics.setShader(characterColoursShader)
	characterColoursShader:send("palette", paletteImage)
	for x = 0, game.framebufferWidth - 1 do
		local column = game.currentFramebuffer[x]
		for y = 0, game.framebufferHeight - 1 do
			local cell = column[y]
			local characterId = consts.cp437Map[cell.character]
			local fontX = characterId % consts.fontWidthCharacters
			local fontY = math.floor(characterId / consts.fontWidthCharacters)
			characterQuad:setViewport(
				fontX * characterWidth, fontY * characterHeight,
				characterWidth, characterHeight,
				fontImage:getDimensions()
			)
			characterColoursShader:send("backgroundColourPosition", consts.colourCoords[cell.backgroundColour])
			characterColoursShader:send("foregroundColourPosition", consts.colourCoords[cell.foregroundColour])
			love.graphics.draw(fontImage, characterQuad, x * characterWidth, y * characterHeight)
		end
	end
	love.graphics.setShader()
end
