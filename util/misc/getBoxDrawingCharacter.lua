-- TODO: Test all

-- Ordered in trinary with places 0 to 3 being right, up, left, then down,
-- and the values in each place being the number of lines on that side.
local chars = {nil, nil, nil, nil, "└", "╘", nil, "╙", "╚", nil, "─", nil, "┘", "┴", nil, "╜", "╨", nil, nil, nil, "═", "╛", nil, "╧", "╝", nil, "╩", nil, "┌", "╒", "│", "├", "╞", nil, nil, nil, "┐", "┬", nil, "┤", "┼", nil, nil, nil, nil, "╕", nil, "╤", "╡", nil, "╪", nil, nil, nil, nil, "╓", "╔", nil, nil, nil, "║", "╟", "╠", "╖", "╥", nil, nil, nil, nil, "╢", "╫", nil, "╗", nil, "╦", nil, nil, nil, "╣", nil, "╬"}

-- Check that all box drawing characters appear once. Doesn't check for correct positioning, though.
-- May as well leave this here
local err = false
for i = 179, 218 do
	local char = require("consts").cp437Map[i]
	local found = 0
	for _, char_ in pairs(chars) do
		if char_ == char then
			found = found + 1
		end
	end
	if found ~= 1 then
		print(char .. " appears " .. found .. " times in the getBoxDrawingCharacter map (should be 1)")
		err = true
	end
end
if err then
	error("Errors in CP437 box drawing map. Check terminal output")
end

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
