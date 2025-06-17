return function(t)
	local ret = {}
	for i = 1, #t do
		ret[i] = t[i]
	end
	for i = #t, 2, -1 do
		local j = love.math.random(i)
		ret[i], ret[j] = ret[j], ret[i]
	end
	return ret
end
