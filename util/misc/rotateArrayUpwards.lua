return function(t)
	for i = #t, 2, -1 do
		t[i], t[i - 1] = t[i - 1], t[i]
	end
end
