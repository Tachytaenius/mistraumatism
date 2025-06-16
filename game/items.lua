local consts = require("consts")
local util = require("util")
local commands = require("commands")

local game = {}

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
	if self:isEntitySwimming(entity) and not gunType.worksInLiquid then
		if entity == self.state.player then
			-- NOTE: Assumed the liquid is water
			self:announce("The gun won't work underwater.", "darkGrey")
		end
	else
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
					bleedRateAdd = roundType.bleedRateAdd,
					instantBloodLoss = roundType.instantBloodLoss,
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

function game:takeItemFromSlot(entity, slotNumber)
	if not entity.inventory then
		return
	end
	if not entity.inventory[slotNumber] then
		return
	end
	local item = entity.inventory[slotNumber].item
	entity.inventory[slotNumber].item = table.remove(entity.inventory[slotNumber].otherItems) -- Can be nil
	return item
end

function game:isItemStackable(itemA, itemB)
	if itemA.itemType.stackable and itemA.itemType == itemB.itemType then
		if itemA.itemType.isAmmo and itemA.fired ~= itemB.fired then
			return false
		end
		return true
	end
	return false
end

function game:addItemToSlot(entity, slotNumber, item)
	assert(item, "Tried to add a nil item to an inventory")
	if not entity.inventory then
		return
	end
	local slot = entity.inventory[slotNumber]
	if not slot then
		return
	end
	if not slot.item or (
		self:isItemStackable(slot.item, item) and
		self:getSlotStackSize(entity, slotNumber) < self:getMaxStackSize(slot.item)
	) then
		table.insert(slot.otherItems, slot.item)
		slot.item = item
		return true
	end
	return false
end

function game:dropItemFromSlot(entity, selectedSlotNumber, targetX, targetY)
	local item = self:takeItemFromSlot(entity, selectedSlotNumber)
	if item then
		self:newItemEntity(targetX, targetY, item)
	end
end

function game:dropAllItemsFromSlot(entity, selectedSlotNumber, targetX, targetY)
	if not entity.inventory then
		return
	end
	local slot = entity.inventory[selectedSlotNumber]
	if not slot then
		return
	end
	while slot.item or #slot.otherItems > 0 do
		self:dropItemFromSlot(entity, selectedSlotNumber, targetX, targetY)
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

function game:getFirstFreeInventorySlotForItem(entity, item)
	if not entity.inventory then
		return nil
	end
	for i, slot in ipairs(entity.inventory) do
		if
			not slot.item or
			self:isItemStackable(slot.item, item) and self:getSlotStackSize(entity, i) < self:getMaxStackSize(slot.item)
		then
			return i
		end
	end
	return nil
end

function game:getMaxStackSize(item)
	local itemType = item.itemType
	if not itemType.stackable then
		return 1
	end
	return itemType.maxStackSize or consts.itemDefaultMaxStackSize
end

function game:getSlotStackSize(entity, slotNumber)
	if not entity.inventory then
		return
	end
	local slot = entity.inventory[slotNumber]
	if not slot then
		return
	end
	return (slot.item and 1 or 0) + #slot.otherItems
end

return game
