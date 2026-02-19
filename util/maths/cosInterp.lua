local consts = require("consts")

return function (a, b, i)
	if i <= 0 then
		return a
	elseif i >= 1 then
		return b
	end
	local i2 = 1 - (math.cos(consts.tau * i / 2) * 0.5 + 0.5)
	return a + (b - a) * i2
end
