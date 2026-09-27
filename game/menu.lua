local commandTypes = require("commandTypes")
local commands = require("commands")

local game = {}

function game:initMenu()
	self:pauseSound()

	self.menuInfo = {
		oldMode = self.mode
	}
	self.mode = "menu"
	local controlsList = {}
	local group
	for line in love.filesystem.lines("rebindList.txt") do
		if line:sub(1, 1) == "\"" then
			group = {name = line:sub(2, -2)}
			table.insert(controlsList, group)
		else
			local binding, name = line:match("([^ ]*) (.*)")
			table.insert(group, {binding = binding, name = name})
		end
	end
	self.menuInfo.controlsSelector = 1
	self.menuInfo.controlsList = controlsList
end

function game:exitMenu()
	self:resumeSound()
	self.mode = self.menuInfo.oldMode
	self.menuInfo = nil
end

function game:updateMenu(dt)
	if commands.checkCommand("menu") then
		return true
	end
end

return game
