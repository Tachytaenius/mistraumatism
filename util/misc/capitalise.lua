local function capitaliseWord(str)
	return str:sub(1, 1):upper() .. str:sub(2)
end

return function(str, capitaliseAll)
	if not capitaliseAll then
		return capitaliseWord(str)
	end
	return str:gsub("%a[^%s]*", capitaliseWord)
end
