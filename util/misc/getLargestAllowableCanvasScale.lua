return function(canvasWidth, canvasHeight)
	-- Doesn't account for title bar etc
	local _, _, flags = love.window.getMode()
	local w, h = love.window.getDesktopDimensions(flags.display)
	return math.min(
		math.floor(w / canvasWidth),
		math.floor(h / canvasHeight)
	)
end
