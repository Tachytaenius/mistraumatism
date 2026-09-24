local settings = require("settings")
local consts = require("consts")

local commands = {}

local commandTypes = require("commandTypes")

commands.previousTickRepeatKeys = {}
commands.pressed = {}

local controls = {}

local function areAnyKeysDown(keys)
	if not keys then
		return false
	end
	for _, key in ipairs(keys) do
		if love.keyboard.isDown(key) then
			return true
		end
	end
	return false
end

local function doAnyKeysMatch(keys, key)
	if not keys then
		return false
	end
	for _, v in ipairs(keys) do
		if v == key then
			return true
		end
	end
	return false
end

local function areModifiersOK(commandValue)
	if not commandValue.group then
		return true
	end
	for modifier in pairs(commandValue.group.relevantModifiers) do
		local expected = not not commandValue.modifiers[modifier]
		local found = not not commands.checkModifier(modifier)
		if found ~= expected then
			return false
		end
	end
	return true
end

function commands.compileControls()
	controls = {}
	for _, t in ipairs({settings.inputBindings, consts.fixedControls}) do
		for k, v in pairs(t) do
			if commandTypes.commandGroups[k] then
				for command in pairs(commandTypes.commandGroups[k]) do
					if command == "isGroup" or command == "relevantModifiers" or command == "groupName" then
						goto continue
					end
					controls[command] = controls[command] or {}
					table.insert(controls[command], v)
				    ::continue::
				end
			end

			controls[k] = controls[k] or {}
			table.insert(controls[k], v)
		end
	end
end

-- Call this at the start of every love.update
function commands.tickStarted(dt)
	commands.compileControls()

	commands.thisTickRepeatKeys = {}
	for command, commandKey in pairs(controls) do
		-- TODO: fix cursor
		local commandValue = commandTypes.commands[command]
		if not commandValue then
			-- Hopefully a group or a modifier
			goto continue
		end
		if commandValue.type ~= "repeat" then
			goto continue
		end
		if not areModifiersOK(commandValue) then
			goto continue
		end
		if areAnyKeysDown(controls[commandValue.group and commandValue.group.groupName or command]) then
			local previous = commands.previousTickRepeatKeys[command]
			local thisTick
			if previous then
				local timerNow = previous.timer - dt
				if timerNow <= 0 then
					timerNow = settings.input.keyRepeatTimerLength
					thisTick = {triggered = true, timer = timerNow}
				else
					thisTick = {triggered = false, timer = timerNow}
				end
			else
				thisTick = {triggered = true, timer = settings.input.initialKeyRepeatTimerLength}
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
	for command, commandKey in pairs(controls) do
		if not commandTypes.commands[command] then
			-- Hopefully a group or a modifier
			goto continue
		end
		local commandValue = commandTypes.commands[command]
		if doAnyKeysMatch(controls[commandValue.group and commandValue.group.groupName or command], pressedKey) and commandTypes.commands[command].type == "pressed" and areModifiersOK(commandTypes.commands[command]) then
			commands.pressed[command] = true
		end
	    ::continue::
	end
end

function commands.checkCommand(command)
	local value = commandTypes.commands[command]
	if not value then
		error("Unknown command " .. command)
	end
	local type = value.type
	if not areModifiersOK(value) then
		return false
	end
	if type == "hold" then
		return areAnyKeysDown(controls[value.group and value.group.groupName or command])
	elseif type == "pressed" then
		return commands.pressed[command]
	elseif type == "repeat" then
		local info = commands.thisTickRepeatKeys[command]
		return info and info.triggered
	end
	error("Command " .. command .. " has an unknown type")
end

function commands.checkModifier(name)
	if not commandTypes.modifiers[name] then
		error("Unknown command modifier " .. name)
	end
	return areAnyKeysDown(controls[name])
end

return commands
