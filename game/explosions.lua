local consts = require("consts")

local game = {}

function game:explode(x, y, radius, damage, cause)
	for tileX = x - radius, x + radius do
		for tileY = y - radius, y + radius do
			local tile = self:getTile(tileX, tileY)
			if not tile then
				goto continue
			end
			if self:tileBlocksAirMotion(tileX, tileY) then
				goto continue
			end
			local dist = self:distance(x, y, tileX, tileY)
			if dist > radius then
				goto continue
			end
			if not self:hitscan(x, y, tileX, tileY, self.tileBlocksAirMotion) then
				goto continue
			end
			local add = math.floor(math.max(0, 1 - dist / radius) * damage)
			if add <= 0 then
				goto continue
			end
			self.state.map.explosionTiles[tile] = true
			local visualAdd = add + love.math.random(0, math.floor(add / 4))
			if not tile.explosionInfo then
				tile.explosionInfo = {damagesThisTick = {}}
				tile.explosionInfo.visual = visualAdd
			else
				tile.explosionInfo.visual = tile.explosionInfo.visual + visualAdd
			end
			tile.explosionInfo.damagesThisTick[#tile.explosionInfo.damagesThisTick+1] = {
				damage = add,
				bleedRateAdd = add * 16,
				instantBloodLoss = add,
				cause = cause
			}

		    ::continue::
		end
	end
end

function game:diminishExplosions()
	local set = self.state.map.explosionTiles
	for tile in pairs(set) do
		if tile.explosionInfo then
			while #tile.explosionInfo.damagesThisTick > 0 do
				table.remove(tile.explosionInfo.damagesThisTick)
			end
			tile.explosionInfo.visual = math.floor(tile.explosionInfo.visual * math.exp(-consts.explosionVisualDiminishRate))

			if tile.explosionInfo.visual <= 0 then
				tile.explosionInfo = nil
			end
		end

		if not tile.explosionInfo then
			set[tile] = nil
		end
	end
end

return game
