local consts = require("consts")
local util = require("util")
local commands = require("commands")

local game = {}

function game:loadItemTypes()
	local state = self.state
	local itemTypes = {}
	state.itemTypes = itemTypes

	itemTypes.pistol = {
		isGun = true,
		tile = "¬",
		ammoClass = "bulletSmall",
		displayName = "pistol",
		extraSpread = nil,
		shotCooldownTimerLength = 2,
		operationTimerLength = 2,
		extraDamage = 1,
		manual = false,
		magazine = false,
		magazineRequired = true,
		magazineClass = "pistol"
	}

	itemTypes.pistolMagazine = {
		magazine = true,
		tile = "■",
		displayName = "pistol mag",
		magazineCapacity = 9,
		magazineClass = "pistol",
		ammoClass = "bulletSmall",
	}

	itemTypes.smallBullet = {
		isAmmo = true,
		tile = "i",
		ammoClass = "bulletSmall",
		displayName = "small bullet",
		spread = 0,
		damage = 12,
		bulletCount = 1,
		projectileSubtickMoveTimerLength = 18,
		range = 17
	}

	itemTypes.pumpShotgun = {
		isGun = true,
		tile = "⌐",
		ammoClass = "shellMedium",
		displayName = "pump shotgun",
		extraSpread = nil,
		shotCooldownTimerLength = 1,
		operationTimerLength = 2,
		extraDamage = 1,
		manual = true,
		magazine = true,
		magazineCapacity = 5
	}

	itemTypes.shotgunShell = {
		isAmmo = true,
		tile = "▬",
		ammoClass = "shellMedium",
		displayName = "shotgun shell",
		spread = 0.1,
		damage = 3,
		bulletCount = 9,
		projectileSubtickMoveTimerLength = 20,
		range = 16
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

	if itemType.magazine then
		new.magazineData = new.magazineData or {}
	end

	return new
end

function game:shootGun(entity, action, gun, targetEntity)
	if entity.entityType ~= "creature" or entity.dead then
		return
	end
	if not self:getHeldItem(entity) or self:getHeldItem(entity) ~= gun or not gun.itemType.isGun then
		return
	end

	if gun.shotCooldownTimer then
		if entity == self.state.player then
			self:announce("The gun won't fire that fast.", "darkGrey")
		end
		return
	end
	local gunType = gun.itemType
	if not gun.cocked then
		if entity == self.state.player then
			self:announce("The trigger does nothing.", "darkGrey")
		end
		return
	end
	gun.cocked = false
	if gun.chamberedRound and not gun.chamberedRound.fired then
		gun.chamberedRound.fired = true
		gun.shotCooldownTimer = gunType.shotCooldownTimerLength
		local roundType = gun.chamberedRound.itemType
		local aimX, aimY = entity.x + action.relativeX, entity.y + action.relativeY
		local entityHitRandomSeed = love.math.random(0, 2 ^ 32 - 1) -- So that you can't shoot every entity on a single tile with a single shotgun blast
		for _=1, roundType.bulletCount or 1 do
			local spread = (roundType.spread or 0) + (gunType.extraSpread or 0)
			spread = spread ~= 0 and spread or nil
			self:newProjectile({
				shooter = entity,
				startX = entity.x,
				startY = entity.y,
				tile = "∙",
				colour = "darkGrey",
				subtickMoveTimerLength = roundType.projectileSubtickMoveTimerLength,
				damage = roundType.damage + (gunType.extraDamage or 0),
				range = roundType.range,
				entityHitRandomSeed = entityHitRandomSeed,

				aimX = aimX,
				aimY = aimY,
				bulletSpread = spread,

				targetEntity = targetEntity -- Can be nil
			})
		end
	else
		if entity == self.state.player then
			self:announce("The gun just clicks.", "darkGrey")
		end
	end
end

function game:cycleGun(gun, x, y)
	if gun.chamberedRound then
		if x and y then
			self:newItemEntity(x, y, gun.chamberedRound)
		end
		gun.chamberedRound = nil
	end
	local magazineData = gun.magazineData or gun.insertedMagazine and gun.insertedMagazine.magazineData or nil
	if magazineData and #magazineData > 0 then
		local potentialRound = magazineData[#magazineData]
		if potentialRound.itemType.ammoClass == gun.itemType.ammoClass then
			gun.chamberedRound = table.remove(magazineData) -- Same round
		end
	end
	gun.cocked = true
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

function game:getHeldItem(entity)
	if not entity.inventory then
		return nil
	end
	if not entity.inventory.selectedSlot then
		return nil
	end
	return entity.inventory[entity.inventory.selectedSlot].item -- Can be nil
end

function game:dropItemFromSlot(entity, selectedSlotNumber, targetX, targetY)
	if not entity.inventory then
		return
	end
	if not entity.inventory[selectedSlotNumber] then
		return
	end
	local item = entity.inventory[selectedSlotNumber].item
	if item then
		self:newItemEntity(targetX, targetY, item)
		entity.inventory[selectedSlotNumber].item = nil
	end
end

function game:getFirstFreeInventorySlot(entity)
	if not entity.inventory then
		return nil
	end
	for i, slot in ipairs(entity.inventory) do
		if not slot.item then
			return i
		end
	end
	return nil
end

return game
