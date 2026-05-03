return function(t)
	for i = 1, #t - 1 do
		t[i], t[i + 1] = t[i + 1], t[i]
	end
end
