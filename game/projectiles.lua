local consts = require("consts")
local util = require("util")

local function progressTimeWithTimer(curTime, timer, age)
	local usableTime = consts.projectileSubticks - curTime
	local timer2 = math.max(timer - usableTime, 0) -- use usableTime to progress/increase timer, stopping at 0
	local usableTime2 = usableTime - (timer - timer2) -- get new used usable time using change in timer
	local timeUsed = usableTime - usableTime2
	local curTime2 = curTime + timeUsed
	local age2 = age + timeUsed
	return curTime2, timer2, age2
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
		local function checkForEntityHit() -- Returns true if the projectile should stop
			for _, entity in ipairs(state.entities) do
				if entity.entityType ~= "creature" or entity.dead then
					goto continue
				end
				if not (entity.x == projectile.currentX and entity.y == projectile.currentY) then
					goto continue
				end
				if not (entity == projectile.shooter and not projectile.moved) then -- Safety
					local damage = projectile.damage
					entity.health = entity.health - damage
					entity.blood = entity.blood - damage
					return true
				end
			    ::continue::
			end
			return false
		end
		if checkForEntityHit() then -- Initial check before moving in case something walked into it
			projectilesToStop[projectile] = true
		else
			while currentTime < consts.projectileSubticks do
				if not projectile.trajectoryOctant then
					-- Projectile age is not increased in this branch
					projectilesToStop[projectile] = true
					break
				else
					currentTime, projectile.moveTimer, projectile.subtickAge = progressTimeWithTimer(currentTime, projectile.moveTimer, projectile.subtickAge)
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
						local currentOctantY = projectile.currentOctantY or 0
						self:computeVisibilityMapOctant(octant, startX, startY, rangeLimit, currentOctantX + 1, localX * 4 - 1, localY * 4 + 1, localX * 4 + 1, localY * 4 - 1, true, visibilityMapInfo)
						if visibilityMapInfo.collidedX == currentOctantX + 1 then
							projectilesToStop[projectile] = true
							checkForEntityHit()
							break
						end
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
						local realLineAngle = math.atan2(localY, localX)
						local function realLineCloseness(tile)
							local realTileAngle = math.atan2(tile.localY, tile.localX)
							local angleDifference = util.getShortestAngleDifference(realLineAngle, realTileAngle)
							return angleDifference
						end
						for _, hitTile in ipairs(potentialNextTiles) do
							if hitTile.localX == minimumX then
								if not newTile or math.abs(realLineCloseness(hitTile)) < math.abs(realLineCloseness(newTile)) then
									newTile = hitTile
								end
							end
						end
						if not newTile then
							projectilesToStop[projectile] = true
							checkForEntityHit()
							break
						end
						local distance = math.sqrt(
							(newTile.globalX - projectile.currentX) ^ 2 +
							(newTile.globalY - projectile.currentY) ^ 2
						)
						projectile.currentOctantX = newTile.localX
						projectile.currentOctantY = newTile.localY
						projectile.currentX = newTile.globalX
						projectile.currentY = newTile.globalY
						projectile.moved = true
						projectile.moveTimer = math.floor(distance * projectile.subtickMoveTimerLength)
						if projectile.moveTimer <= 0 then -- Avoid a hang in case distance fails (why would it?)
							projectilesToStop[projectile] = true
							checkForEntityHit()
							break
						end

						if checkForEntityHit() then
							projectilesToStop[projectile] = true
							break
						end
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

local uncopiedParameters = util.arrayToSet({
	"aimX", "aimY", "bulletSpread"
})
function game:newProjectile(parameters)
	local newProjectile = {}
	for k, v in pairs(parameters) do
		if not uncopiedParameters[k] then
			newProjectile[k] = v
		end
	end

	local targetX, targetY
	if not (parameters.aimX == parameters.startX and parameters.aimY == parameters.startX) and parameters.bulletSpread then
		local relativeX = parameters.aimX - parameters.startX
		local relativeY = parameters.aimY - parameters.startY
		local angle = math.atan2(relativeY, relativeX)
		local newAngle = angle + (love.math.random() - 0.5) * parameters.bulletSpread
		local r = consts.spreadRetargetDistance
		targetX = math.floor(math.cos(newAngle) * r + 0.5) + parameters.startX -- Round
		targetY = math.floor(math.sin(newAngle) * r + 0.5) + parameters.startY
	else
		targetX = parameters.aimX
		targetY = parameters.aimY
	end

	newProjectile.currentX = parameters.startX
	newProjectile.currentY = parameters.startY
	newProjectile.targetX = targetX
	newProjectile.targetY = targetY
	newProjectile.subtickAge = 0
	newProjectile.moved = false
	newProjectile.moveTimer = 0

	if newProjectile.startX == newProjectile.targetX and newProjectile.startY == newProjectile.targetY then
		-- No trajectory
	else
		local hitscanResult, info = self:hitscan(newProjectile.startX, newProjectile.startY, newProjectile.targetX, newProjectile.targetY)
		local trajectoryOctant
		if hitscanResult then
			-- An octant actually hit the end result, so pick it as the trajectory octant for the projectile
			trajectoryOctant = info.octant
		else
			-- Get the octant of the two which got furthest, if there were two
			-- This is the most likely branch for a spread projectile, for which the target location is no longer exact
			if #info.triedHitTiles == 1 then
				trajectoryOctant = info.triedHitTiles[1].octant
			else
				local function getMaxDistance(hitTiles)
					local currentMax = -math.huge -- Works fine if #hitTiles == 0
					-- Probably could just check which has a greater number of hit tiles, or only check the distance of the last one, or whatever
					for _, tile in ipairs(hitTiles) do
						local tileDistance = math.sqrt(tile.localX ^ 2 + tile.localY ^ 2)
						currentMax = math.max(currentMax, tileDistance)
					end
					return currentMax
				end
				if getMaxDistance(info.triedHitTiles[1].hitTiles) >= getMaxDistance(info.triedHitTiles[2].hitTiles) then
					trajectoryOctant = info.triedHitTiles[1].octant
				else
					trajectoryOctant = info.triedHitTiles[2].octant
				end
			end
		end
		newProjectile.trajectoryOctant = trajectoryOctant
	end

	self.state.projectiles[#self.state.projectiles+1] = newProjectile
end

return game
