local version = love.filesystem.read("version.txt") -- This file is provided on build
version = version or "unknown"

local util = require("util")
util.load()

local game = require("game")

local consts = require("consts")
local commands = require("commands")
local settings = require("settings")

local mouseHideTimer

function love.load(args)
	for _, arg in ipairs(args) do
		if arg == "--help" then
			print("Yes, you are loved :)")
		elseif arg == "--version" then
			print(version)
			love.event.quit()
			return
		end
	end
	love.graphics.setDefaultFilter("nearest")
	game.version = version
	game:init(args)
	mouseHideTimer = consts.mouseHideTimerLength
end

function love.keypressed(key)
	if key == consts.keyUnbinder and not (game.menuInfo and game.menuInfo.rebinding) then
		game:keyUnbinderPressed()
		return
	end
	if game.menuInfo and game.menuInfo.rebinding then
		local rebindKey = key
		if key == consts.keyUnbinder then
			rebindKey = false
		end
		if key == "escape" or game:rebindToKey(game.menuInfo.controlToRebind, rebindKey) then
			game.menuInfo.rebindDone = true
		end
	else
		commands.keyPressed(key)
	end
end

local function handleSettings()
	love.audio.setVolume(settings.sound.masterVolume)

	-- Window should've been made already
	local prevFullscreen = settings.graphics.fullscreen
	settings.graphics.fullscreen = love.window.getFullscreen()
	local shouldRemakeWindow
	local shouldRemakeEndCanvasses
	local settingChanged = not not prevFullscreen == not not settings.graphics.fullscreen
	local largest = util.getLargestAllowableCanvasScale(game:getCanvasSize())
	local initialCanvasScale = settings.graphics.canvasScale
	if initialCanvasScale > largest then
		settings.graphics.canvasScale = largest
		settingChanged = true
		shouldRemakeEndCanvasses = true
		if not settings.graphics.fullscreen then
			shouldRemakeWindow = true
		end
	end
	if commands.checkCommand("decreaseCanvasScale") then
		if settings.graphics.canvasScale > 1 then
			settings.graphics.canvasScale = settings.graphics.canvasScale - 1
			settingChanged = true
			shouldRemakeEndCanvasses = true
			if not settings.graphics.fullscreen then
				shouldRemakeWindow = true
			end
		end
	end
	if commands.checkCommand("increaseCanvasScale") then
		if settings.graphics.canvasScale < largest then
			settings.graphics.canvasScale = settings.graphics.canvasScale + 1
			settingChanged = true
			shouldRemakeEndCanvasses = true
			if not settings.graphics.fullscreen then
				shouldRemakeWindow = true
			end
		end
	end
	if commands.checkCommand("toggleFullscreen") then
		settings.graphics.fullscreen = not settings.graphics.fullscreen
		settingChanged = true
		if settings.graphics.fullscreen then
			love.window.setFullscreen(true, "desktop")
			-- If you change canvas scale and toggle fullscreen at the same time, there can be some buggy behaviour about which display is selected.
			-- But when entering fullscreen mode, you won't need to remake the window anyway, so:
			shouldRemakeWindow = false
		else
			shouldRemakeWindow = true
		end
	end
	if shouldRemakeEndCanvasses then
		game:handleResize()
	end
	if shouldRemakeWindow then
		game:remakeWindow()
	end
	if settingChanged then
		settings("save")
	end
end

function love.update(dt)
	commands.tickStarted(dt)

	mouseHideTimer = math.max(0, mouseHideTimer - dt)
	love.mouse.setVisible(mouseHideTimer > 0)

	handleSettings()

	local repeatUpdate -- For changing state and not immediately drawing before updating it
	repeat
		repeatUpdate = game:realtimeUpdate(dt)
		if game.quitting then
			return
		end
		repeatUpdate = repeatUpdate or game.forceRepeatUpdate
		game.forceRepeatUpdate = false
	until not repeatUpdate

	game.realTime = game.realTime + dt

	commands.tickFinished()
end

function love.draw()
	if game.quitting then
		return
	end
	game:draw()

	-- love.graphics.print(love.timer.getFPS())
end

function love.mousemoved()
	mouseHideTimer = consts.mouseHideTimerLength
end

function love.resize()
	game:handleResize()
end
