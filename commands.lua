local settings = require("settings")

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

	wait = "hold",
	waitPrecise = "pressed",

	shoot = "pressed"
}

commands.pressed = {}

-- Call this at the end of every love.update
function commands.tickFinished()
	commands.pressed = {}
end

-- Call this on every love.keypressed
function commands.keyPressed(pressedKey)
	for command, commandKey in pairs(settings.controls) do
		if commandTypes[command] == "pressed" and pressedKey == commandKey then
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
	end
	error("Unknown command type " .. type)
end

return commands
