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
	if entity.entityType == "creature" and not entity.dead then
		if entity.heldItem and entity.heldItem == gun and gun.itemType.isGun then
			local gunType = gun.itemType
			local aimX, aimY = entity.x + action.relativeX, entity.y + action.relativeY
			for _=1, gunType.bulletCount or 1 do
				self:newProjectile({
					shooter = entity,
					startX = entity.x,
					startY = entity.y,
					tile = "∙",
					colour = "darkGrey",
					subtickMoveTimerLength = gunType.projectileSubtickMoveTimerLength,
					damage = gunType.damage,

					aimX = aimX,
					aimY = aimY,
					bulletSpread = gunType.bulletSpread
				})
			end
		end
	end
end

return game
