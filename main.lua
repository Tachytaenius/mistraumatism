-- love entrypoint

local util = require("util")
util.load()

local game = require("game")

local util = require("util")
local commands = require("commands")
local settings = require("settings")

function love.load(args)
	love.graphics.setDefaultFilter("nearest")
	game:init(args)
end

function love.keypressed(key)
	commands.keyPressed(key)
end

local function handleSettingsCommands()
	-- Window should've been made already
	local shouldRemakeWindow
	if commands.checkCommand("decreaseCanvasScale") then
		if settings.graphics.canvasScale > 1 then
			settings.graphics.canvasScale = settings.graphics.canvasScale - 1
			if not settings.graphics.fullscreen then
				shouldRemakeWindow = true
			end
		end
	end
	if commands.checkCommand("increaseCanvasScale") then
		if settings.graphics.canvasScale < util.getLargestAllowableCanvasScale(game:getCanvasSize()) then
			settings.graphics.canvasScale = settings.graphics.canvasScale + 1
			if not settings.graphics.fullscreen then
				shouldRemakeWindow = true
			end
		end
	end
	if commands.checkCommand("toggleFullscreen") then
		settings.graphics.fullscreen = not settings.graphics.fullscreen
		if settings.graphics.fullscreen then
			love.window.setFullscreen(true, "desktop")
			-- If you change canvas scale and toggle fullscreen at the same time, there can be some buggy behaviour about which display is selected.
			-- But when entering fullscreen mode, you won't need to remake the window anyway, so:
			shouldRemakeWindow = false
		else
			shouldRemakeWindow = true
		end
	end
	if shouldRemakeWindow then
		util.remakeWindow(game:getCanvasSize())
	end
end

function love.update(dt)
	commands.tickStarted(dt)

	handleSettingsCommands()

	local repeatUpdate -- For changing state and not immediately drawing before updating it
	repeat
		repeatUpdate = game:realtimeUpdate(dt)
	until not repeatUpdate

	commands.tickFinished()
end

function love.draw()
	game:draw()

	-- love.graphics.print(love.timer.getFPS())
end
