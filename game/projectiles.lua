local consts = require("consts")

local function progressTimeWithTimer(curTime, timer)
	assert(curTime <= consts.projectileSubticks)
	local usableTime = consts.projectileSubticks - curTime
	local timer2 = math.max(timer - usableTime, 0) -- use usableTime to progress/increase timer, stopping at 0
	local usableTime2 = usableTime - (timer - timer2) -- get new used usable time using change in timer
	local curTime2 = curTime + (usableTime - usableTime2) -- progress current time by how much usable time was used
	assert(timer2 <= timer)
	assert(usableTime2 <= usableTime)
	assert(curTime2 >= curTime)
	assert(curTime2 <= consts.projectileSubticks)
	return curTime2, timer2
end

local game = {}

function game:tileBlocksProjectiles(x, y)
	local tile = self:getTile(x, y)
	if not tile then
		return true
	end
	return self.state.tileTypes[tile.type].solidity == "solid"
end

function game:updateProjectiles()
	local state = self.state

	local projectilesToStop = {}
	for _, projectile in ipairs(state.projectiles) do
		local currentTime = 0
		while currentTime < consts.projectileSubticks do
			if not projectile.trajectoryOctant then
				projectilesToStop[projectile] = true
				break
			else
				currentTime, projectile.moveTimer = progressTimeWithTimer(currentTime, projectile.moveTimer)
				if projectile.moveTimer <= 0 then
					local startX, startY = projectile.startX, projectile.startY
					local endX, endY = projectile.targetX, projectile.targetY

					local deltaX, deltaY = endX - startX, endY - startY
					local magX, magY = math.abs(deltaX), math.abs(deltaY)
					local rangeLimit = math.max(magX, magY)

					local octant = projectile.trajectoryOctant
					local localX, localY
					local quadrant = math.floor(octant / 2)
					if (octant + quadrant) % 2 == 0 then
						localX, localY = magX, magY
					else
						localX, localY = magY, magX
					end

					local blockFunction = self.tileBlocksProjectiles
					local visibilityMapInfo = {
						projectile = true,
						wholeMap = false,
						-- Don't need globalEndX etc
						blockFunction = blockFunction,
						hitTiles = {}
					}

					local currentOctantX = projectile.currentOctantX or 0
					self:computeVisibilityMapOctant(octant, startX, startY, rangeLimit, currentOctantX + 1, localX * 4 - 1, localY * 4 + 1, localX * 4 + 1, localY * 4 - 1, true, visibilityMapInfo)
					local hitTiles = visibilityMapInfo.hitTiles

					local potentialNextTiles = {}
					local minimumX = math.huge
					for _, hitTile in ipairs(hitTiles) do
						if not blockFunction(self, hitTile.globalX, hitTile.globalY) then
							minimumX = math.min(minimumX, hitTile.localX)
							potentialNextTiles[#potentialNextTiles+1] = hitTile
						end
					end
					local newTile
					for _, hitTile in ipairs(potentialNextTiles) do
						if hitTile.localX == minimumX then
							-- Just pick the first one (TODO: make it try to follow what full FOV octants see?)
							newTile = hitTile
							break
						end
					end
					if not newTile then
						projectilesToStop[projectile] = true
						break
					end
					local distance = math.sqrt(
						(newTile.globalX - projectile.currentX) ^ 2 +
						(newTile.globalY - projectile.currentY) ^ 2
					)
					projectile.currentOctantX = newTile.localX
					projectile.currentX = newTile.globalX
					projectile.currentY = newTile.globalY
					projectile.moveTimer = math.floor(distance * projectile.subtickMoveTimerLength)
					if projectile.moveTimer <= 0 then
						projectilesToStop[projectile] = true
						break
					end
				end
			end
		end
	end

	local i = 1
	while i <= #state.projectiles do
		local projectile = state.projectiles[i]
		if projectilesToStop[projectile] then
			table.remove(state.projectiles, i) -- Could swap with end
		else
			i = i + 1
		end
	end
end

return game
