local commands = require("commands")

local game = {}

function game:initMenu()
	self.menuInfo = {
		oldMode = self.mode
	}
	self.mode = "menu"
end

function game:exitMenu()
	self.mode = self.menuInfo.oldMode
	self.menuInfo = nil
end

function game:updateMenu(dt)
	if commands.checkCommand("menu") then
		return true
	end
end

return game
