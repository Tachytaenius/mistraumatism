return function(a, b)
	if a == b then
		return true
	end
	if #a ~= #b then
		return false
	end
	for i, aV in ipairs(a) do
		if aV ~= b[i] then
			return false
		end
	end
	return true
end
