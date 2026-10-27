local commandTypes = require("commandTypes")
local commands = require("commands")
local settings = require("settings")
local consts = require("consts")

local game = {}

function game:popSubmenuAllowed()
	return true
end

function game:popSubmenu()
	table.remove(self.menuInfo.submenuStack)

	if #self.menuInfo.submenuStack == 0 then
		return true
	end
	return false
end

function game:pushSubmenu(name)
	local new = {}
	new.cursorPos = 1
	new.scroll = 0
	if name == "mainMenu" then
		new.title = "Main Menu"
		new.showVersion = true
		table.insert(new, {
			displayName = "Exit Menu",
			onSelect = function()
				self:exitMenu()
			end
		})
		table.insert(new, {
			displayName = "Settings",
			onSelect = function()
				self:pushSubmenu("settings")
			end
		})
		table.insert(new, {
			displayName = "Help",
			onSelect = function()
				self:pushSubmenu("help")
			end
		})
		if self.menuInfo.oldMode ~= "title" then
			table.insert(new, {
				displayName = "Quit to Title",
				onSelect = function()
					self:pushSubmenu("quitTitle")
				end
			})
		end
		table.insert(new, {
			displayName = "Close Game",
			onSelect = function()
				self:pushSubmenu("quit")
			end
		})
	elseif name == "quitTitle" then
		new.title = "Quit to Title?"
		table.insert(new, {
			displayName = "No, keep playing",
			onSelect = function()
				self:popSubmenu()
			end
		})
		table.insert(new, {
			displayName = "Yes, quit to title",
			onSelect = function()
				self.menuInfo = nil
				self.enterTitleFunction()
			end
		})
	elseif name == "quit" then
		new.title = "Close Game?"
		table.insert(new, {
			displayName = "No, keep playing",
			onSelect = function()
				self:popSubmenu()
			end
		})
		table.insert(new, {
			displayName = "Yes, close game now",
			onSelect = function()
				self.quitting = true
				love.event.quit()
			end
		})
	elseif name == "keybindings" then
		new.title = "Keybindings"
		new.showControls = true
		new.needsScroll = true
		new.help = {
			"Press [BACKSPACE] to unbind or reset an input.",
			"Press [ESCAPE] to cancel rebinding."
		}
		table.insert(new, {
			displayName = "Back",
			onSelect = function()
				self:popSubmenu()
			end
		})
		table.insert(new, {
			displayName = "Reset all to defaults",
			onSelect = function()
				settings("resetSection", "inputBindings")
				settings("save")
			end
		})
	elseif name == "help" then
		new.title = "Help"
		table.insert(new, {
			displayName = "Back",
			onSelect = function()
				self:popSubmenu()
			end
		})
		table.insert(new, {displayName = "TODO"})
	elseif name == "input" then
		new.title = "Input"
		table.insert(new, {
			displayName = "Back",
			onSelect = function()
				self:popSubmenu()
			end
		})
		table.insert(new, {displayName = "TODO"})
	elseif name == "graphics" then
		new.title = "Graphics"
		table.insert(new, {
			displayName = "Back",
			onSelect = function()
				self:popSubmenu()
			end
		})
		table.insert(new, {displayName = "TODO"})
	elseif name == "audio" then
		new.title = "Audio"
		table.insert(new, {
			displayName = "Back",
			onSelect = function()
				self:popSubmenu()
			end
		})
		table.insert(new, {
			displayName = "Master Volume",
			onSelect = function()
				local bar = self:pushSubmenu("bar")
				bar.settingCategory = "sound"
				bar.settingName = "masterVolume"
				bar.title = "Master Volume"
			end
		})
		table.insert(new, {
			displayName = "Music Volume",
			onSelect = function()
				local bar = self:pushSubmenu("bar")
				bar.settingCategory = "sound"
				bar.settingName = "musicVolume"
				bar.title = "Music Volume"
			end
		})
		table.insert(new, {
			displayName = "Sound Effects Volume",
			onSelect = function()
				local bar = self:pushSubmenu("bar")
				bar.settingCategory = "sound"
				bar.settingName = "soundVolume"
				bar.title = "Sound Effects Volume"
			end
		})
	elseif name == "settings" then
		new.title = "Settings"
		table.insert(new, {
			displayName = "Back",
			onSelect = function()
				self:popSubmenu()
			end
		})
		table.insert(new, {
			displayName = "Keybindings",
			onSelect = function()
				self:pushSubmenu("keybindings")
			end
		})
		table.insert(new, {
			displayName = "Input",
			onSelect = function()
				self:pushSubmenu("input")
			end
		})
		table.insert(new, {
			displayName = "Graphics",
			onSelect = function()
				self:pushSubmenu("graphics")
			end
		})
		table.insert(new, {
			displayName = "Audio",
			onSelect = function()
				self:pushSubmenu("audio")
			end
		})
	elseif name == "bar" then
		new.drawType = "bar"
		new.isBar = true
		new.drawNext = true
		new.popOnConfirmWithoutEntry = true
	else
		error("Unknown submenu name " .. tostring(name))
	end
	table.insert(self.menuInfo.submenuStack, new)
	return new
end

function game:initMenu()
	self:pauseSound()

	self.menuInfo = {
		oldMode = self.mode,
		submenuStack = {}
	}
	self.mode = "menu"

	self:pushSubmenu("mainMenu")

	local controlsList = {}
	local group
	self.menuInfo.controlsListLen = 0
	for line in love.filesystem.lines("rebindList.txt") do
		if line:sub(1, 1) == "\"" then
			group = {name = line:sub(2, -2)}
			table.insert(controlsList, group)
		else
			local binding, name = line:match("([^ ]*) (.*)")
			table.insert(group, {binding = binding, name = name})
			self.menuInfo.controlsListLen = self.menuInfo.controlsListLen + 1
		end
	end
	self.menuInfo.controlsList = controlsList
end

function game:exitMenu()
	self:resumeSound()
	self.mode = self.menuInfo.oldMode
	self.menuInfo = nil
end

function game:updateMenuScroll()
	local curSubmenu = self.menuInfo.submenuStack[#self.menuInfo.submenuStack]
	if curSubmenu.needsScroll then
		local cur = self:getMenuCursorY()
		local max = self:getMaxMenuCursorY()
		local height = self.framebufferHeight
		local margin = 6
		local screenY = cur - curSubmenu.scroll
		if screenY <= margin then
			curSubmenu.scroll = cur - margin
		elseif screenY >= height - margin then
			curSubmenu.scroll = cur - (height - margin) + 1
		end
		curSubmenu.scroll = math.max(0, math.min(max - height + 2, curSubmenu.scroll))
	end
end

function game:updateMenu(dt)
	if self.menuInfo.rebinding and self.menuInfo.rebindDone then
		self.menuInfo.rebinding = false
		self.menuInfo.controlToRebind = nil
		self.menuInfo.controlToRebindDisplayName = nil
		self.menuInfo.rebindDone = nil
		return
	end

	if commands.checkCommand("menu") then
		if self:popSubmenuAllowed() then
			return self:popSubmenu()
		end
	end

	local curSubmenu = self.menuInfo.submenuStack[#self.menuInfo.submenuStack]

	if curSubmenu.isBar then
		local change = 0
		if commands.checkCommand("scrollListBackwards") then
			change = change - 1
		end
		if commands.checkCommand("scrollListForwards") then
			change = change + 1
		end
		if change ~= 0 then
			local steps = consts.audioSteps
			local value = settings[curSubmenu.settingCategory][curSubmenu.settingName]
			value = math.floor(value * steps + 0.5) / steps
			value = math.max(0, math.min(1, value + change / steps))
			settings[curSubmenu.settingCategory][curSubmenu.settingName] = value
			settings("save")
		end
	else
		local cursorPosZero = curSubmenu.cursorPos - 1
		local len = #curSubmenu
		if curSubmenu.showControls then
			len = len + self.menuInfo.controlsListLen
		end
		if commands.checkCommand("scrollListBackwards") then
			cursorPosZero = (cursorPosZero - 1) % len
		end
		if commands.checkCommand("scrollListForwards") then
			cursorPosZero = (cursorPosZero + 1) % len
		end
		curSubmenu.cursorPos = cursorPosZero + 1
	end

	self:updateMenuScroll()

	if commands.checkCommand("confirm") then
		local entry = curSubmenu[curSubmenu.cursorPos]
		if not entry and curSubmenu.showControls then
			local binding, name = self:getSelectedKeybinding()
			self.menuInfo.controlToRebind = binding
			self.menuInfo.controlToRebindDisplayName = name
			self.menuInfo.rebinding = true
		elseif not entry and curSubmenu.popOnConfirmWithoutEntry then
			if self:popSubmenuAllowed() then
				self:popSubmenu()
			end
		elseif entry and entry.onSelect then
			entry.onSelect()
		end
	end
end

function game:getSelectedKeybinding()
	if not self.menuInfo then
		return nil
	end
	local curSubmenu = self.menuInfo.submenuStack[#self.menuInfo.submenuStack]
	if not curSubmenu.showControls then
		return nil
	end

	local controlIndex = curSubmenu.cursorPos - #curSubmenu
	local i = 1
	local binding
	for _, group in ipairs(self.menuInfo.controlsList) do
		for _, b in ipairs(group) do
			if i == controlIndex then
				binding = b
				break
			end
			i = i + 1
		end
		if binding then
			break
		end
	end
	if not binding then
		-- ???
		return nil
	end
	return binding.binding, binding.name
end

function game:rebindToKey(binding, key)
	if consts.fixedControlsUsedKeys[key] then
		return false
	end
	settings.inputBindings[binding] = key
	settings("save")
	return true
end

function game:keyUnbinderPressed()
	local binding = self:getSelectedKeybinding()
	if not binding then
		return
	end
	if settings.inputBindings[binding] == false then
		settings("resetSingle", "inputBindings", binding)
		settings("save")
		return
	end
	self:rebindToKey(binding, false) -- nil would be reset to default
end

function game:getMaxMenuCursorY()
	return self:getMenuCursorY(math.huge)
end

function game:getMenuCursorY(override) -- Should match graphics
	local curSubmenu = self.menuInfo.submenuStack[#self.menuInfo.submenuStack]
	local remaining = override or curSubmenu.cursorPos
	local y = 2

	if curSubmenu.help then
		y = y + #curSubmenu.help + 1
	end

	local lastReturnableY = y

	for _ in ipairs(curSubmenu) do
		remaining = remaining - 1
		lastReturnableY = y
		if remaining == 0 then
			return y
		end
		y = y + 1
	end
	y = y + 1

	if curSubmenu.showControls then
		for _, group in ipairs(self.menuInfo.controlsList) do
			y = y + 1

			for _ in ipairs(group) do
				remaining = remaining - 1
				lastReturnableY = y
				if remaining == 0 then
					return y
				end
				y = y + 1
			end

			y = y + 1
		end
	end

	-- ???
	return lastReturnableY
end

return game
