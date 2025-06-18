local game = {}

function game:tickGibs()
	local state = self.state
	local gibsToRemove = {}
	for _, gib in ipairs(state.gibs) do
		self:moveObjectAsProjectile(gib, nil, nil, gibsToRemove)
		if gib.bloodMaterial and gib.bloodAmount > 0 then -- and (gib.bloodAmount >= 3 or love.math.random() < 1/3) then
			local bloodRemoved = math.min(1, gib.bloodAmount)
			gib.bloodAmount = gib.bloodAmount - bloodRemoved
			self:addSpatter(gib.currentX, gib.currentY, gib.bloodMaterial, bloodRemoved)
			if gib.bloodAmount <= 0 and gib.fleshAmount <= 0 then
				gibsToRemove[gib] = true
			end
		end
	end
	local i = 1
	while i <= #state.gibs do
		local gib = state.gibs[i]
		if gibsToRemove[gib] then
			self:dropGib(gib) -- Removes this gib
		else
			i = i + 1
		end
	end
end

function game:dropGib(gib)
	local state = self.state
	if gib.bloodMaterial and gib.bloodAmount > 0 then
		self:addSpatter(gib.currentX, gib.currentY, gib.bloodMaterial, gib.bloodAmount)
		gib.bloodAmount = 0
	end
	if gib.fleshMaterial and gib.fleshAmount > 0 then
		self:addSpatter(gib.currentX, gib.currentY, gib.fleshMaterial, gib.fleshAmount)
		gib.fleshAmount = 0
	end
	for i, v in ipairs(state.gibs) do
		if v == gib then
			table.remove(state.gibs, i)
			break
		end
	end
end

return game
