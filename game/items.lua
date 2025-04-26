local util = require("util")

local game = {}

function game:loadItemTypes()
	local state = self.state
	local itemTypes = {}
	state.itemTypes = itemTypes

	itemTypes.pistol = {
		isGun = true,
		bulletCount = 1,
		damage = 16,
		manual = false,
		shotCooldownTimerLength = 4,
		projectileSubtickMoveTimerLength = 256
	}
end

local uncopiedParameters = util.arrayToSet({
	"itemTypeName"
})
function game:newItemData(parameters) -- Will have to be stored inside an entity or whatever
	local state = self.state

	local new = {}
	for k, v in pairs(parameters) do
		if not uncopiedParameters[k] then
			new[k] = v
		end
	end

	local itemType = state.itemTypes[parameters.itemTypeName]
	new.itemType = itemType

	if itemType.isGun then
		new.shotCooldownTimer = 0 -- Ready to fire
	end

	return new
end

function game:updateItems()
	local state = self.state

	for _, entity in ipairs(state.entities) do
		if entity.entityType == "creature" then
			if entity.shootInfo and entity.heldItem and entity.heldItem.itemType.isGun then
				local gun = entity.heldItem
				local gunType = gun.itemType
				local newProjectile = {
					shooter = entity,
					startX = entity.x,
					startY = entity.y,
					currentX = entity.x,
					currentY = entity.y,
					targetX = entity.shootInfo.targetX,
					targetY = entity.shootInfo.targetY,
					tile = "∙",
					colour = "darkGrey",
					subtickMoveTimerLength = gunType.projectileSubtickMoveTimerLength,
					damage = gunType.damage,

					subtickAge = 0,
					moved = false,
					moveTimer = 0
				}
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
				state.projectiles[#state.projectiles+1] = newProjectile
			end
		end
	end
end

return game
