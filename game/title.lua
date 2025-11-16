local commands = require("commands")

local game = {}

function game:initTitle(exitFunction)
	self.titleInfo = {
		exitFunction = exitFunction,
		-- drawTitleTime = 4,
		-- fireStartTime = 1,
		drawTitleTime = 3,

		time = 0
	}
end

function game:updateTitle(dt)
	local info = self.titleInfo
	info.time = info.time + dt
	if info.time >= self.titleInfo.drawTitleTime and commands.checkCommand("confirm") then
		return self.titleInfo.exitFunction()
	end
end

return game
