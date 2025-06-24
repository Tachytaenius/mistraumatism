-- love entrypoint

local game = require("game") -- util loaded in here

local commands = require("commands")

function love.load(args)
	love.graphics.setDefaultFilter("nearest")
	game:init(args)
end

function love.keypressed(key)
	commands.keyPressed(key)
end

function love.update(dt)
	commands.tickStarted(dt)
	local repeatUpdate -- For changing state and not immediately drawing before updating it
	repeat
		repeatUpdate = game:realtimeUpdate(dt)
	until not repeatUpdate
	commands.tickFinished()
end

function love.draw()
	game:draw()
end
