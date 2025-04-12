return function(t)
	local ret = {}
	for _, v in ipairs(t) do
		ret[v] = true
	end
	return ret
end
