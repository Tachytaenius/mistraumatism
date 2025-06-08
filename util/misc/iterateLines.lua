return function(str)
	if str:sub(-1) ~= "\n" then
		str = str .. "\n"
	end
	return str:gmatch("(.-)\n")
end