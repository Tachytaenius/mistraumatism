local settings = require("settings")
local consts = require("consts")

local commands = {}

local commandTypes = {
	moveRight = "hold",
	moveUpRight = "hold",
	moveUp = "hold",
	moveUpLeft = "hold",
	moveLeft = "hold",
	moveDownLeft = "hold",
	moveDown = "hold",
	moveDownRight = "hold",

	moveCursor = "hold",
	moveCursorRight = "repeat",
	moveCursorUpRight = "repeat",
	moveCursorUp = "repeat",
	moveCursorUpLeft = "repeat",
	moveCursorLeft = "repeat",
	moveCursorDownLeft = "repeat",
	moveCursorDown = "repeat",
	moveCursorDownRight = "repeat",
	lockOn = "pressed",
	clearCursor = "pressed",
	deselectTarget = "pressed",

	wait = "hold",
	waitPrecise = "pressed",

	shoot = "pressed",
	melee = "pressed",
	useHeldItem = "pressed",

	scrollListBackwards = "repeat",
	scrollListForwards = "repeat",

	dropMode = "hold",
	pickUpOrDrop = "pressed",
	reloadMode = "hold",
	unloadMode = "hold",
	handleInventorySlot1 = "pressed",
	handleInventorySlot2 = "pressed",
	handleInventorySlot3 = "pressed",
	handleInventorySlot4 = "pressed",
	handleInventorySlot5 = "pressed",
	handleInventorySlot6 = "pressed",
	handleInventorySlot7 = "pressed",
	handleInventorySlot8 = "pressed",
	handleInventorySlot9 = "pressed",
	deselectInventorySlot = "pressed"
}

commands.previousTickRepeatKeys = {}
commands.pressed = {}

-- Call this at the start of every love.update
function commands.tickStarted(dt)
	commands.thisTickRepeatKeys = {}
	for command, commandKey in pairs(settings.controls) do
		if commandTypes[command] ~= "repeat" then
			goto continue
		end
		if love.keyboard.isDown(commandKey) then
			local previous = commands.previousTickRepeatKeys[command]
			local thisTick
			if previous then
				local timerNow = previous.timer - dt
				if timerNow <= 0 then
					timerNow = consts.keyRepeatTimerLength
					thisTick = {triggered = true, timer = timerNow}
				else
					thisTick = {triggered = false, timer = timerNow}
				end
			else
				thisTick = {triggered = true, timer = consts.initialKeyRepeatTimerLength}
			end
			commands.thisTickRepeatKeys[command] = thisTick
		end
	    ::continue::
	end
end

-- Call this at the end of every love.update
function commands.tickFinished()
	commands.previousTickRepeatKeys, commands.thisTickRepeatKeys = commands.thisTickRepeatKeys, nil
	commands.pressed = {}
end

-- Call this on every love.keypressed
function commands.keyPressed(pressedKey)
	for command, commandKey in pairs(settings.controls) do
		if pressedKey == commandKey and commandTypes[command] == "pressed" then
			commands.pressed[command] = true
		end
	end
end

function commands.checkCommand(command)
	local type = commandTypes[command]
	if type == "hold" then
		return love.keyboard.isDown(settings.controls[command])
	elseif type == "pressed" then
		return commands.pressed[command]
	elseif type == "repeat" then
		local info = commands.thisTickRepeatKeys[command]
		return info and info.triggered
	end
	error("Unknown command type " .. type)
end

return commands
