local consts = require("consts")
local util = require("util")

local game = {}

function game:loadItemTypes()
	local state = self.state
	local itemTypes = {}
	state.itemTypes = itemTypes

	itemTypes.pistol = {
		isGun = true,
		tile = "¬",
		displayName = "pistol",
		bulletCount = 1,
		bulletSpread = nil,
		shotCooldownTimerLength = 4,
		damage = 16,
		manual = false,
		projectileSubtickMoveTimerLength = 16,
		range = 17
	}

	itemTypes.shotgun = {
		isGun = true,
		tile = "¬",
		displayName = "shotgun",
		bulletCount = 9,
		bulletSpread = 0.1,
		shotCooldownTimerLength = 14,
		damage = 2, -- Per projectile
		manual = true,
		projectileSubtickMoveTimerLength = 20,
		range = 16,
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

function game:shootGun(entity, action, gun, targetEntity)
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
					range = gunType.range,

					aimX = aimX,
					aimY = aimY,
					bulletSpread = gunType.bulletSpread,

					targetEntity = targetEntity -- Can be nil
				})
			end
		end
	end
end

function game:registerPickUp(entity, itemEntity)
	assert(self.entityPickUps, "No entityPickUps table. Is this function being used in its intended place?")
	local pickupTable
	for _, t in ipairs(self.entityPickUps) do
		if t.item == itemEntity then
			pickupTable = t
			break
		end
	end
	if not pickupTable then
		pickupTable = {item = itemEntity}
		self.entityPickUps[#self.entityPickUps+1] = pickupTable
	end
	pickupTable[#pickupTable+1] = entity
end

return game