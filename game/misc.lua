local consts = require("consts")

local game = {}

function game:getDirectionOffset(direction)
	if direction == "right" then
		return 1, 0
	elseif direction == "upRight" then
		return 1, -1
	elseif direction == "up" then
		return 0, -1
	elseif direction == "upLeft" then
		return -1, -1
	elseif direction == "left" then
		return -1, 0
	elseif direction == "downLeft" then
		return -1, 1
	elseif direction == "down" then
		return 0, 1
	elseif direction == "downRight" then
		return 1, 1
	else
		error("Unknown direction " .. direction)
	end
end

function game:getDirectionOffsetNormalised(direction)
	local d = consts.diagonal
	if direction == "right" then
		return 1, 0
	elseif direction == "upRight" then
		return d, -d
	elseif direction == "up" then
		return 0, -1
	elseif direction == "upLeft" then
		return -d, -d
	elseif direction == "left" then
		return -1, 0
	elseif direction == "downLeft" then
		return -d, d
	elseif direction == "down" then
		return 0, 1
	elseif direction == "downRight" then
		return d, d
	else
		error("Unknown direction " .. direction)
	end
end

function game:isDirectionDiagonal(direction)
	if direction == "right" then
		return false
	elseif direction == "upRight" then
		return true
	elseif direction == "up" then
		return false
	elseif direction == "upLeft" then
		return true
	elseif direction == "left" then
		return false
	elseif direction == "downLeft" then
		return true
	elseif direction == "down" then
		return false
	elseif direction == "downRight" then
		return true
	else
		error("Unknown direction " .. direction)
	end
end

return game
