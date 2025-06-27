local consts = require("consts")
local settings = require("settings")

return function(canvasWidth, canvasHeight)
	local _, _, flags = love.window.getMode()
	local currentDisplay = flags.display

	love.window.setMode(
		canvasWidth * settings.graphics.canvasScale,
		canvasHeight * settings.graphics.canvasScale,
		{
			fullscreen = settings.graphics.fullscreen,
			borderless = settings.graphics.fullscreen,
			display = currentDisplay
		}
	)
	love.window.setIcon(love.image.newImageData("icon.png"))
	love.window.setTitle(consts.windowTitle)
end
