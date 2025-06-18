local consts = require("consts")
local util = require("util")

local game = {}

function game:tileBlocksAirMotion(x, y)
	local tile = self:getTile(x, y)
	if not tile then
		return true
	end
	if tile.doorData and not tile.doorData.open then
		return true
	end
	return self.state.tileTypes[tile.type].solidity == "solid"
end

function game:moveObjectAsProjectile(projectile, checkForEntityHit, tryExplode, projectilesToStop)
	checkForEntityHit = checkForEntityHit or function() end
	tryExplode = tryExplode or function() end
	if checkForEntityHit() then -- Initial check before moving in case something walked into it
		tryExplode()
		projectilesToStop[projectile] = true
	else
		local currentTime = 0
		while currentTime < consts.projectileSubticks do
			if not projectile.trajectoryOctant then
				-- Already did checkForEntityHit
				tryExplode()
				projectilesToStop[projectile] = true
				break
			else
				currentTime, projectile.moveTimer, projectile.subtickAge = util.progressSubtickTimeAndTimer(currentTime, projectile.moveTimer, projectile.subtickAge, consts.projectileSubticks)
				if projectile.moveTimer <= 0 then
					local startX, startY = projectile.startX, projectile.startY
					local endX, endY = projectile.targetX, projectile.targetY
					local rangeLimit = projectile.range + 4 -- Add a buffer just to be sure, since we use actual float distance checks
					-- Recalculate endX and endY to be pushed as far as needed because going beyond them will cause issues (like the sector for the singleLine computeVisibilityMapOctant starting to spread out)
					-- Single line checks that have their delta to their target multiplied by an integer >= 2 actually seem to have lower collidedX values, this is probably because the sector is narrower. That said, we still reach our destinations if they are visible. This has been exhaustively tested
					-- All of this is probably horrible and horribly done
					local startToTargetX = projectile.targetX - startX
					local startToTargetY = projectile.targetY - startY
					while
						math.max(
							math.abs(endX - startX),
							math.abs(endY - startY)
						) <= rangeLimit
					do
						endX = endX + startToTargetX
						endY = endY + startToTargetY
					end

					local deltaX, deltaY = endX - startX, endY - startY
					local magX, magY = math.abs(deltaX), math.abs(deltaY)
					local disableDistanceCheck = false

					local octant = projectile.trajectoryOctant
					local localX, localY
					local quadrant = math.floor(octant / 2)
					if (octant + quadrant) % 2 == 0 then
						localX, localY = magX, magY
					else
						localX, localY = magY, magX
					end

					local currentOctantX = projectile.currentOctantX or 0
					local currentOctantY = projectile.currentOctantY or 0

					local blockFunction = self.tileBlocksAirMotion

					local singleLineVisibilityMapInfo = {
						singleLine = true,
						wholeMap = false,
						blockFunction = blockFunction,
						hitTiles = {},
						distanceCheckRangeLimit = projectile.range
					}
					self:computeVisibilityMapOctant(
						octant,
						startX, startY,
						rangeLimit, currentOctantX + 1,
						localX * 4 - 1, localY * 4 + 1,
						localX * 4 + 1, localY * 4 - 1,
						disableDistanceCheck,
						singleLineVisibilityMapInfo
					)
					if singleLineVisibilityMapInfo.collidedX == currentOctantX + 1 then
						projectilesToStop[projectile] = true
						checkForEntityHit()
						tryExplode()
						break
					end

					local visibilityMapInfo = {
						wholeMap = false,
						blockFunction = blockFunction,
						hitTiles = {},
						distanceCheckRangeLimit = projectile.range,
						sectorsNextStep = {}
					}
					if not projectile.previousSectors then
						self:computeVisibilityMapOctant(
							octant,
							startX, startY,
							rangeLimit, currentOctantX + 1,
							1, 1,
							1, 0,
							disableDistanceCheck,
							visibilityMapInfo,
							true
						)
					else
						for _, sector in ipairs(projectile.previousSectors) do
							self:computeVisibilityMapOctant(
								octant,
								startX, startY,
								rangeLimit, currentOctantX + 1,
								sector.slopeTopX, sector.slopeTopY,
								sector.slopeBottomX, sector.slopeBottomY,
								disableDistanceCheck,
								visibilityMapInfo,
								true
							)
						end
					end
					local hitTiles = visibilityMapInfo.hitTiles

					local potentialNextTiles = {}
					local minimumX = math.huge
					for _, hitTile in ipairs(hitTiles) do
						if
							hitTile.fullHit and -- Visible
							singleLineVisibilityMapInfo.hitTiles[hitTile.tile] and -- On the actual single line path
							not blockFunction(self, hitTile.globalX, hitTile.globalY) -- Available tile to path on
						then
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
							-- Ensure we always go through the target location (if it is available to be pathed on)
							local previousNewTileIsOriginalTargetTile = newTile and newTile.globalX == projectile.targetX and newTile.globalY == projectile.targetY
							local isOriginalTargetTile = hitTile.globalX == projectile.targetX and hitTile.globalY == projectile.targetY

							if not previousNewTileIsOriginalTargetTile and (not newTile or (isOriginalTargetTile or math.abs(realLineCloseness(hitTile)) < math.abs(realLineCloseness(newTile)))) then
								newTile = hitTile
							end
						end
					end
					if not newTile then
						projectilesToStop[projectile] = true
						checkForEntityHit()
						tryExplode()
						break
					end
					projectile.previousSectors = visibilityMapInfo.sectorsNextStep[newTile.localX + 1]
					local distance = self:distance(projectile.currentX, projectile.currentY, newTile.globalX, newTile.globalY)
					projectile.currentOctantX = newTile.localX
					projectile.currentOctantY = newTile.localY
					projectile.currentX = newTile.globalX
					projectile.currentY = newTile.globalY
					projectile.moved = true
					projectile.piercedInfo = {}
					projectile.moveTimer = math.floor(distance * projectile.subtickMoveTimerLength)
					if projectile.moveTimer <= 0 then -- Avoid a hang in case distance fails (why would it?)
						projectilesToStop[projectile] = true
						checkForEntityHit()
						tryExplode()
						break
					end

					if checkForEntityHit() then
						projectilesToStop[projectile] = true
						tryExplode()
						break
					end
				end
			end
		end
		-- Done with subticks
		if projectile.subtickMoveTimerLengthChange then
			projectile.subtickMoveTimerLength = projectile.subtickMoveTimerLength + projectile.subtickMoveTimerLengthChange
		end
		if projectile.subtickMoveTimerLengthMin then
			projectile.subtickMoveTimerLength = math.max(projectile.subtickMoveTimerLength, projectile.subtickMoveTimerLengthMin)
		end
		if projectile.subtickMoveTimerLengthMax then
			projectile.subtickMoveTimerLength = math.min(projectile.subtickMoveTimerLength, projectile.subtickMoveTimerLengthMax)
		end
	end
end

function game:updateProjectiles()
	local state = self.state

	local projectilesToStop = {}
	for _, projectile in ipairs(state.projectiles) do
		local function checkForEntityHit() -- Returns true if the projectile should stop
			local potentialHits = {}
			for _, entity in ipairs(state.entities) do
				if entity.entityType ~= "creature" or (entity.dead and not projectile.hitDeadEntities) then
					goto continue
				end
				if not (entity.x == projectile.currentX and entity.y == projectile.currentY) then
					goto continue
				end
				local pierced = projectile.piercedInfo[entity]
				if pierced and pierced.x == entity.x and pierced.y == entity.y then
					goto continue
				end
				local wouldHitFriendly
				if projectile.shooter then
					wouldHitFriendly = entity == projectile.shooter or self:getTeamRelation(projectile.shooter.team, entity.team) == "friendly"
				end
				if not (wouldHitFriendly and not projectile.moved) or projectile.noShooterSafety then -- Safety
					potentialHits[#potentialHits+1] = entity
				end
			    ::continue::
			end
			if #potentialHits == 0 then
				return false
			end
			local hitEntity
			for _, entity in ipairs(potentialHits) do
				if entity == projectile.targetEntity then
					hitEntity = entity
					break
				end
			end
			if not hitEntity then
				local randomIndex = projectile.entityHitRandomSeed and (projectile.entityHitRandomSeed % #potentialHits + 1) or love.math.random(#potentialHits)
				hitEntity = potentialHits[randomIndex]
			end
			local damage = projectile.damage
			self:damageEntity(hitEntity, damage, projectile.shooter, projectile.bleedRateAdd, projectile.instantBloodLoss)
			projectile.piercedInfo[hitEntity] = {x = hitEntity.x, y = hitEntity.y}
			projectile.pierces = (projectile.pierces or 0) + 1
			return projectile.pierces > (projectile.maxPierces or 0)
		end
		local function tryExplode()
			if projectile.explosionRadius then
				self:explode(projectile.currentX, projectile.currentY, projectile.explosionRadius, projectile.explosionDamage, projectile.shooter)
			end

			if projectile.projectileExplosionProjectiles then
				for _, projectileType in ipairs(projectile.projectileExplosionProjectiles) do
					for _=1, projectileType.count do
						-- These new projectiles should be ticked for the first time in the same tick as this explosion
						self:newProjectile({
							shooter = projectile.shooter,
							startX = projectile.currentX,
							startY = projectile.currentY,

							tile = projectileType.tile or "∙",
							colour = projectileType.colour or "darkGrey",
							subtickMoveTimerLength = math.min(
								projectileType.subtickMoveTimerLengthMin or math.huge,
								love.math.random(
									projectileType.subtickMoveTimerLength,
									projectileType.subtickMoveTimerLength * 4
								)
							),
							subtickMoveTimerLengthChange = projectileType.subtickMoveTimerLengthChange,
							subtickMoveTimerLengthMin = projectileType.subtickMoveTimerLengthMin,
							subtickMoveTimerLengthMax = projectileType.subtickMoveTimerLengthMax,
							damage = projectileType.damage,
							bleedRateAdd = projectileType.bleedRateAdd,
							instantBloodLoss = projectileType.instantBloodLoss,
							range = projectileType.range,
							maxPierces = projectileType.maxPierces,
							projectileExplosionProjectiles = projectileType.projectileExplosionProjectiles, -- Too much recursion may not be wise here
							explosionRadius = projectileType.explosionRadius,
							explosionDamage = projectileType.explosionDamage,

							entityHitRandomSeed = projectile.entityHitRandomSeed,

							aimX = projectile.currentX + 1,
							aimY = projectile.currentY,
							bulletSpread = consts.tau,

							noShooterSafety = true
						})
					end
				end
			end
		end
		self:moveObjectAsProjectile(projectile, checkForEntityHit, tryExplode, projectilesToStop)
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

function game:initProjectileTrajectory(newProjectile, startX, startY, targetX, targetY)
	newProjectile.currentX = startX
	newProjectile.currentY = startY
	newProjectile.targetX = targetX
	newProjectile.targetY = targetY
	newProjectile.subtickAge = 0
	newProjectile.moved = false
	newProjectile.moveTimer = 0

	if newProjectile.startX == newProjectile.targetX and newProjectile.startY == newProjectile.targetY then
		-- No trajectory
	else
		local blockFunction = self.tileBlocksAirMotion
		local hitscanResult, info = self:hitscan(newProjectile.startX, newProjectile.startY, newProjectile.targetX, newProjectile.targetY, blockFunction)
		local trajectoryOctant
		if hitscanResult then
			-- An octant actually hit the end result, so pick it as the trajectory octant for the projectile
			trajectoryOctant = info.octant
		else
			-- Get the octant of the two which got furthest, if there were two
			-- This is the most likely branch for a spread projectile, for which the target location is no longer exact
			if #info.octants == 1 then
				trajectoryOctant = info.octants[1].octant
			else
				if info.octants[1].collidedX >= info.octants[2].collidedX then
					trajectoryOctant = info.octants[1].octant
				else
					trajectoryOctant = info.octants[2].octant
				end
			end
		end
		newProjectile.trajectoryOctant = trajectoryOctant
	end
end

local uncopiedParameters = util.arrayToSet({
	"aimX", "aimY", "bulletSpread"
})
function game:newProjectile(parameters)
	local newProjectile = {}
	newProjectile.piercedInfo = {}
	for k, v in pairs(parameters) do
		if not uncopiedParameters[k] then
			newProjectile[k] = v
		end
	end

	local targetX, targetY
	if not (parameters.aimX == parameters.startX and parameters.aimY == parameters.startY) and parameters.bulletSpread then
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

	self:initProjectileTrajectory(newProjectile, parameters.startX, parameters.startY, targetX, targetY)

	self.state.projectiles[#self.state.projectiles+1] = newProjectile

	return newProjectile
end

return game
