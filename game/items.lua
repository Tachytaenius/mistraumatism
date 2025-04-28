local consts = require("consts")
local util = require("util")

local game = {}

function game:loadItemTypes()
	local state = self.state
	local itemTypes = {}
	state.itemTypes = itemTypes

	itemTypes.pistol = {
		isGun = true,
		bulletCount = 1,
		bulletSpread = nil,
		shotCooldownTimerLength = 4,
		damage = 16,
		manual = false,
		projectileSubtickMoveTimerLength = 16
	}

	itemTypes.shotgun = {
		isGun = true,
		bulletCount = 9,
		bulletSpread = 0.1,
		shotCooldownTimerLength = 14,
		damage = 6, -- Per projectile
		manual = true,
		projectileSubtickMoveTimerLength = 20
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

function game:shootGun(entity, action, gun)
	local state = self.state
	if entity.entityType == "creature" and not entity.dead then
		if entity.heldItem and entity.heldItem == gun and gun.itemType.isGun then
			local gunType = gun.itemType
			local aimX, aimY = entity.x + action.relativeX, entity.y + action.relativeY
			for _=1, gunType.bulletCount or 1 do
				local targetX, targetY
				if not (aimX == entity.x and aimY == entity.y) and gunType.bulletSpread then
					local angle = math.atan2(action.relativeX, action.relativeY)
					local newAngle = angle + (love.math.random() - 0.5) * gunType.bulletSpread
					local r = consts.spreadRetargetDistance
					targetX = math.floor(math.cos(newAngle) * r + 0.5) -- Round
					targetY = math.floor(math.sin(newAngle) * r + 0.5)
				else
					targetX = aimX
					targetY = aimY
				end
				local newProjectile = {
					shooter = entity,
					startX = entity.x,
					startY = entity.y,
					currentX = entity.x,
					currentY = entity.y,
					targetX = targetX,
					targetY = targetY,
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
