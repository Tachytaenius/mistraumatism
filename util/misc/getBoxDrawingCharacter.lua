local utf8 = require("utf8")

-- TODO: Test all

-- Ordered in trinary with places 0 to 3 being right, up, left, then down,
-- and the values in each place being the number of lines on that side.
-- ! means the character does not exist
local chars = {nil, nil, nil, nil, "└", "╘", nil, "╙", "╚", nil, "─", nil, "┘", "┴", nil, "╜", "╨", nil, nil, nil, "═", "╛", nil, "╧", "╝", nil, "╩", nil, "┌", "╒", "│", "├", "╞", nil, nil, nil, "┐", "┬", nil, "┤", "┼", nil, nil, nil, nil, nil, nil, "╤", "╡", nil, "╪", nil, nil, nil, nil, "╓", "╔", nil, nil, nil, "║", "╟", "╠", nil, "╥", nil, nil, nil, nil, nil, "╫", nil, "╗", nil, "╦", nil, nil, nil, "╣", nil, "╬"}

local function checkArg(arg)
	assert(arg == 0 or arg == 1 or arg == 2, "Argument should be 0, 1, or 2")
end

return function(right, up, left, down)
	checkArg(right)
	checkArg(up)
	checkArg(left)
	checkArg(down)

	local index =
		right * 3 ^ 0 +
		up    * 3 ^ 1 +
		left  * 3 ^ 2 +
		down  * 3 ^ 3

	return chars[index + 1]
end
