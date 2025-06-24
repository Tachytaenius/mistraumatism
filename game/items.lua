local consts = require("consts")
local util = require("util")
local commands = require("commands")

local game = {}

local uncopiedParameters = util.arrayToSet({
	"itemTypeName"
})
function game:newItemData(parameters)
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
	elseif itemType.energyWeapon then
		new.storedEnergy = 0
		new.chargeState = "hold"
	elseif itemType.energyBattery then
		new.storedEnergy = 0
	end
	if not itemType.noCocking then
		if itemType.alteredMagazineUse == "select" then
			new.cockedStates = {}
		end
	end

	return new
end

function game:getGunMagazine(gun)
	return gun.magazineData or gun.insertedMagazine and gun.insertedMagazine.magazineData
end

function game:shootGun(entity, action, gun, targetEntity, selection, shotResultInfo)
	if entity.entityType ~= "creature" or entity.dead then
		return
	end
	if not self:getHeldItem(entity) or self:getHeldItem(entity) ~= gun or not gun.itemType.isGun then
		return
	end

	if gun.itemType.breakAction and gun.actionOpen then
		return
	end
	if gun.itemType.alteredMagazineUse == "select" then
		assert(selection, "No selection passed to shootGun when firing a selection-type gun")
	end
	local selectType = gun.itemType.alteredMagazineUse == "select"
	local energyType = gun.itemType.energyWeapon
	local function setResult(result)
		local index = selection or 1
		shotResultInfo[index] = result
	end
	local function getCocked()
		if selectType then
			return gun.cockedStates[selection]
		else
			return gun.cocked
		end
	end
	local function setCocked(state)
		if selectType then
			gun.cockedStates[selection] = state
		else
			gun.cocked = state
		end
	end

	if gun.shotCooldownTimer then
		if entity == self.state.player then
			setResult("cooldown")
		end
		return
	end
	local gunType = gun.itemType
	if gunType.autoFeed and not (gunType.noCocking or getCocked()) then
		if not energyType then
			self:cycleGun(gun, entity.x, entity.y)
		end
	end
	if not (gunType.noCocking or energyType) and not getCocked() then
		if entity == self.state.player then
			setResult("nothing")
		end
		return
	end
	if not (energyType or gunType.noCocking) then
		setCocked(false)
	end
	if self:isEntitySwimming(entity) and not gunType.worksInLiquid then
		if entity == self.state.player then
			setResult("inLiquid")
		end
	else
		local roundToShoot
		local fromChamber
		local mag = self:getGunMagazine(gun)
		local function try()
			if gunType.noChamber then
				fromChamber = false
				mag = self:getGunMagazine(gun) -- Integrated or inserted
				roundToShoot = mag and (selectType and mag[selection] or not selectType and mag[#mag])
			else
				fromChamber = true
				roundToShoot = gun.chamberedRound
			end
		end
		try()
		if not roundToShoot and gunType.autoFeed then
			self:cycleGun(gun, entity.x, entity.y)
			try()
		end

		if energyType then
			-- HACK
			roundToShoot = gun.storedEnergy >= gun.itemType.energyPerShot and {
				itemType = gun.itemType.projectile
			}
		end
		if roundToShoot and not roundToShoot.fired then
			if energyType then
				gun.storedEnergy = gun.storedEnergy - gun.itemType.energyPerShot
			end
			local roundType = roundToShoot.itemType
			if roundType.noCasing then
				if fromChamber then
					gun.chamberedRound = nil
				else
					if selectType then
						assert(roundToShoot == mag[selection])
						mag[selection] = nil
					else
						assert(roundToShoot == table.remove(mag))
					end
				end
			else
				roundToShoot.fired = true
			end
			if gunType.automaticEjection then
				gun.ejectorStates = gun.ejectorStates or {}
				gun.ejectorStates[selection] = true
			end
			setResult("fired")
			gun.shotCooldownTimer = gunType.shotCooldownTimerLength -- Can be nil
			local aimX, aimY = entity.x + action.relativeX, entity.y + action.relativeY
			local entityHitRandomSeed = love.math.random(0, 2 ^ 32 - 1) -- So that you can't shoot every entity on a single tile with a single shotgun blast
			for _=1, roundType.bulletCount or 1 do
				local spread = (roundType.spread or 0) + (gunType.extraSpread or 0)
				spread = spread ~= 0 and spread or nil
				self:newProjectile({
					shooter = entity,
					startX = entity.x,
					startY = entity.y,
					tile = roundType.projectileTile or "∙",
					colour = roundType.projectileColour or "darkGrey",
					subtickMoveTimerLength = roundType.projectileSubtickMoveTimerLength,
					subtickMoveTimerLengthChange = roundType.projectileSubtickMoveTimerLengthChange,
					subtickMoveTimerLengthMin = roundType.projectileSubtickMoveTimerLengthMin,
					subtickMoveTimerLengthMax = roundType.projectileSubtickMoveTimerLengthMax,
					damage = roundType.damage + (gunType.extraDamage or 0),
					bleedRateAdd = roundType.bleedRateAdd,
					instantBloodLoss = roundType.instantBloodLoss,
					range = roundType.range,
					entityHitRandomSeed = entityHitRandomSeed,
					maxPierces = roundType.maxPierces,
					projectileExplosionProjectiles = roundType.projectileExplosionProjectiles,
					explosionRadius = roundType.projectileExplosionRadius,
					explosionDamage = roundType.projectileExplosionDamage,

					aimX = aimX,
					aimY = aimY,
					bulletSpread = spread,

					trailParticleInfo = roundType.trailParticleInfo,

					targetEntity = targetEntity -- Can be nil
				})
			end
		else
			if entity == self.state.player then
				setResult(energyType and "nothing" or "click")
			end
		end
	end
end

function game:cycleGun(gun, x, y)
	local magazineData = gun.magazineData or gun.insertedMagazine and gun.insertedMagazine.magazineData or nil
	if gun.itemType.alteredMagazineUse ~= "select" and not gun.itemType.cycleDoesntMoveAmmo then
		if not gun.itemType.noChamber then
			if gun.chamberedRound then
				if x and y then
					self:newItemEntity(x, y, gun.chamberedRound)
				end
				gun.chamberedRound = nil
			end
		else
			local magRound = table.remove(self:getGunMagazine(gun))
			if magRound then
				if x and y then
					self:newItemEntity(x, y, magRound)
				end
			end
		end
		if magazineData and #magazineData > 0 then
			local potentialRound = magazineData[#magazineData]
			if potentialRound.itemType.ammoClass == gun.itemType.ammoClass and not gun.itemType.noChamber then
				gun.chamberedRound = table.remove(magazineData) -- Same round
			end
		end
	end
	if not gun.itemType.noCocking then
		if gun.itemType.alteredMagazineUse == "select" then
			for i = 1, gun.itemType.magazineCapacity do
				gun.cockedStates[i] = true
			end
		else
			gun.cocked = true
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

function game:getBestFreeInventorySlotForItem(entity, item)
	if not entity.inventory then
		return nil
	end
	for i, slot in ipairs(entity.inventory) do
		if slot.item and self:isItemStackable(slot.item, item) and self:getSlotStackSize(entity, i) < self:getMaxStackSize(slot.item) then
			return i
		end
	end
	for i, slot in ipairs(entity.inventory) do
		if not slot.item then
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
