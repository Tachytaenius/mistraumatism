local commands = require("commands")
local consts = require("consts")

local game = {}

function game:loadActionTypes()
	local actionTypes = {}
	self.state.actionTypes = actionTypes

	local function newActionType(name, displayName)
		local new = {name = name}
		assert(displayName, "New action type needs display name")
		new.displayName = displayName
		actionTypes[name] = new
		actionTypes[#actionTypes+1] = new
		return new
	end

	-- Within each function, self is the game instance

	local steady = newActionType("steady", "steady")
	function steady.construct(self, entity, timer)
		local new = {type = "steady"}
		new.timer = timer
		return new
	end
	function steady.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			action.doneType = "completed"
		end
	end

	local move = newActionType("move", "move")
	local function getMoveSpecialTypeDisplayNameOverride(action)
		local specialType = action.specialType
		if not specialType then
			return nil
		end
		return
			specialType == "jump" and (
				action.jumpAirborne and "jump" or
				"jump"
			) or
			specialType == "dodge" and "dodge" or
			specialType == "stopCharge" and "stop charge"
	end
	function move.construct(self, entity, direction, specialType)
		local moveTimerLength = self:getMoveTimerLength(entity, specialType)
		if not moveTimerLength then
			return nil
		end
		local new = {type = "move"}
		assert(direction ~= "zero", "Move action should not use the zero direction")
		new.direction = direction
		local multiplier = self:isDirectionDiagonal(direction) and consts.inverseDiagonal or 1
		new.timer = math.floor(moveTimerLength * multiplier)
		new.specialType = specialType
		if specialType == "dodge" or specialType == "jump" then
			if self:isEntitySwimming(entity) then
				return nil
			end
			if specialType == "jump" then
				if not (
					entity.creatureType.jumpTimerLength and
					entity.creatureType.jumpAirborneTimerLength and
					entity.creatureType.jumpSteadyTimerLength
				) then
					return nil
				end
			else
				if not (
					entity.creatureType.dodgeTimerLength and
					entity.creatureType.dodgeSteadyTimerLength
				) then
					return nil
				end
			end
		end
		if specialType then
			new.displayNameOverride = getMoveSpecialTypeDisplayNameOverride(new)
		end
		new.impedeLevel = 0
		return new
	end
	local function canWalkTo(entity, destinationX, destinationY, ignoreGaps)
		return self:getWalkable(destinationX, destinationY, false, entity.creatureType.flying or ignoreGaps)
	end
	local function moveTo(entity, destinationX, destinationY)
		entity.x, entity.y = destinationX, destinationY
	end
	function move.process(self, entity, action)
		local offsetX, offsetY = self:getDirectionOffset(action.direction)
		local destinationX, destinationY = entity.x + offsetX, entity.y + offsetY
		if canWalkTo(entity, destinationX, destinationY, true) then
			local state = self.state
			local preMoveImpedingEntityLocations = state.preMoveImpedingEntityLocations
			local sizeOnTile =
				preMoveImpedingEntityLocations[entity.x] and
				preMoveImpedingEntityLocations[entity.x][entity.y] and
				preMoveImpedingEntityLocations[entity.x][entity.y].totalSize or 0
			if sizeOnTile > 0 then
				local entitySize = self:getEntitySize(entity)
				local proportion = entitySize / sizeOnTile -- Lower means the entity is more crowded on the tile, higher means the entity is more free to move
				proportion = proportion / (2 * consts.impedenceProportionStart)
				local newImpedeLevel = 0
				if proportion <= 2 ^ -consts.maxImpedeLevel then
					newImpedeLevel = consts.maxImpedeLevel
				else
					newImpedeLevel = math.max(0, -select(2, math.frexp(proportion)))
				end

				local impedeDelta = newImpedeLevel - action.impedeLevel
				if impedeDelta > 0 then
					action.timer = action.timer + impedeDelta * consts.impedenceTimeMultiplier
					action.impedeLevel = newImpedeLevel
				end
			end

			action.timer = action.timer - 1
			local dontComplete = false
			if action.timer <= 0 then
				if action.specialType == "jump" then
					if action.jumpAirborne then
						if entity.creatureType.jumpSteadyTimerLength then
							action.replaceAction = steady.construct(self, entity, entity.creatureType.jumpSteadyTimerLength)
						end
					else
						action.jumpAirborne = true
						if not self:isEntitySwimming(entity) and entity.creatureType.jumpAirborneTimerLength then
							local multiplier = self:isDirectionDiagonal(action.direction) and consts.inverseDiagonal or 1
							action.timer = math.floor(entity.creatureType.jumpAirborneTimerLength * multiplier)
							action.displayNameOverride = getMoveSpecialTypeDisplayNameOverride(action)
							dontComplete = true
						end
					end
				elseif action.specialType == "dodge" then
					if entity.creatureType.dodgeSteadyTimerLength then
						action.replaceAction = steady.construct(self, entity, entity.creatureType.dodgeSteadyTimerLength)
					end
				end
				moveTo(entity, destinationX, destinationY)
				if not dontComplete then
					action.doneType = "completed"
				end
				return
			end
		else
			if action.specialType == "jump" and action.jumpAirborne then
				if entity.creatureType.jumpSteadyTimerLength then
					action.replaceAction = steady.construct(self, entity, entity.creatureType.jumpSteadyTimerLength)
				end
			end
			action.doneType = "cancelled"
		end
	end
	function move.fromInput(self, player)
		local playerMoveTimerLength = self:getMoveTimerLength(player)
		if playerMoveTimerLength then
			local direction
			if commands.checkCommand("dodgeMode") or not commands.checkCommand("moveCursor") then
				if commands.checkCommand("moveRight") then
					direction = "right"
				elseif commands.checkCommand("moveUpRight") then
					direction = "upRight"
				elseif commands.checkCommand("moveUp") then
					direction = "up"
				elseif commands.checkCommand("moveUpLeft") then
					direction = "upLeft"
				elseif commands.checkCommand("moveLeft") then
					direction = "left"
				elseif commands.checkCommand("moveDownLeft") then
					direction = "downLeft"
				elseif commands.checkCommand("moveDown") then
					direction = "down"
				elseif commands.checkCommand("moveDownRight") then
					direction = "downRight"
				end
			end
			if direction then
				local offsetX, offsetY = self:getDirectionOffset(direction)
				local specialType = nil
				if commands.checkCommand("dodgeMode") then
					if self:isEntitySwimming(player) then
						return nil
					end
					if commands.checkCommand("jumpDodgeMode") then
						if
							player.creatureType.jumpTimerLength and
							player.creatureType.jumpAirborneTimerLength and
							player.creatureType.jumpSteadyTimerLength
						then
							specialType = "jump"
						end
					else
						if
							player.creatureType.dodgeTimerLength and
							player.creatureType.dodgeSteadyTimerLength
						then
							specialType = "dodge"
						end
					end
				end
				local ignoreGaps = player.creatureType.flying
				if specialType == "jump" or specialType == "dodge" then
					ignoreGaps = true
				end
				if self:getWalkable(player.x + offsetX, player.y + offsetY, false, ignoreGaps) then
					return move.construct(self, player, direction, specialType)
				end
			end
		end
	end

	local shoot = newActionType("shoot", "shoot")
	function shoot.construct(self, entity, targetX, targetY, targetEntity, shotType, abilityName, magazineSlotSelectionIndex)
		local new = {type = "shoot"}
		new.relativeX = targetX - entity.x
		new.relativeY = targetY - entity.y
		local ability
		if shotType == "ability" then
			if entity.creatureType.projectileAbilities then
				for _, v in ipairs(entity.creatureType.projectileAbilities) do
					if v.name == abilityName then
						ability = v
						break
					end
				end
			end
		end
		new.magazineSlotSelectionIndex = magazineSlotSelectionIndex
		new.timer = ability and ability.shootTime or 1
		new.targetEntity = targetEntity
		new.shotType = shotType
		new.abilityName = abilityName
		return new
	end
	function shoot.process(self, entity, action)
		if action.shotType == "heldItem" then
			if not (self:getHeldItem(entity) and self:getHeldItem(entity).itemType.isGun) then
				action.doneType = "cancelled"
				return
			end
			if self:getHeldItem(entity).itemType.breakAction and self:getHeldItem(entity).actionOpen then
				action.doneType = "cancelled"
				return
			end
		end

		local ability
		if action.shotType == "ability" then
			if entity.creatureType.projectileAbilities then
				for _, v in ipairs(entity.creatureType.projectileAbilities) do
					if v.name == action.abilityName then
						ability = v
						break
					end
				end
			end
		end

		action.timer = action.timer - 1
		if action.timer <= 0 then
			action.doneType = "completed"
			local targetEntity
			if action.targetEntity and action.relativeX + entity.x == action.targetEntity.x and action.relativeY + entity.y == action.targetEntity.y then
				targetEntity = action.targetEntity
			end
			if ability then
				self:abilityShoot(entity, action, ability, targetEntity)
			else
				local shotResultInfo = {}
				if action.magazineSlotSelectionIndex == "all" then
					for i = 1, self:getHeldItem(entity).itemType.magazineCapacity do
						self:shootGun(entity, action, self:getHeldItem(entity), targetEntity, i, shotResultInfo)
					end
				else
					self:shootGun(entity, action, self:getHeldItem(entity), targetEntity, action.magazineSlotSelectionIndex, shotResultInfo)
				end
				local announcementType
				local priority = {"nothing", "click", "cooldown", "inLiquid", "fired"}
				for i, name in ipairs(priority) do
					priority[name] = i
				end
				for _, result in pairs(shotResultInfo) do
					if not announcementType then
						announcementType = result
						goto continue
					end
					-- Order of priority
					if priority[result] > priority[announcementType] then
						announcementType = result
					end
				    ::continue::
				end
				if announcementType then
					local texts = {
						fired = nil,
						inLiquid = "The gun won't work submerged.",
						cooldown = "The gun won't fire that fast.",
						click = "The gun just clicks.",
						nothing = "The gun does nothing."
					}
					if texts[announcementType] then
						self:announce(texts[announcementType], "darkGrey")
					end
					local soundRange = self:getHeldItem(entity).itemType.gunshotSoundRange
					if announcementType == "fired" and soundRange then
						self:broadcastEvent({
							sourceEntity = entity,
							x = entity.x,
							y = entity.y,
							type = "gunshot",
							soundRange = soundRange
						})
					end
				end
			end
		end
	end
	function shoot.fromInput(self, player)
		if not commands.checkCommand("shoot") then
			return
		end
		if not (self:getHeldItem(player) and self:getHeldItem(player).itemType.isGun) then
			return
		end
		if self:getHeldItem(player).itemType.breakAction and self:getHeldItem(player).actionOpen then
			return
		end
		local cursor = self.state.cursor
		if not cursor then
			return
		end
		local magIndex
		if self:getHeldItem(player).itemType.alteredMagazineUse == "select" then
			if commands.checkCommand("operateBarrel1") and commands.checkCommand("operateBarrel2") then
				magIndex = "all"
			elseif commands.checkCommand("operateBarrel1") then
				magIndex = 1
			elseif commands.checkCommand("operateBarrel2") then
				magIndex = 2
			else
				-- Pull triggers for loaded (with live rounds) and cocked barrels first, then try ones with cocked hammers
				for i = 1, self:getHeldItem(player).itemType.magazineCapacity do
					if self:getHeldItem(player).magazineData[i] and not self:getHeldItem(player).magazineData[i].fired and self:getHeldItem(player).cockedStates[i] then
						magIndex = i
						break
					end
				end
				if not magIndex then
					for i = 1, self:getHeldItem(player).itemType.magazineCapacity do
						if self:getHeldItem(player).cockedStates[i] then
							magIndex = i
							break
						end
					end
				end
			end
			if not magIndex then
				return nil
			end
		end
		return shoot.construct(self, player, cursor.x, cursor.y, self:getCursorEntity(), "heldItem", nil, magIndex)
	end

	local melee = newActionType("melee", "melee")
	function melee.construct(self, entity, targetEntity, direction, charge)
		local new = {type = "melee"}
		new.timer = charge and self:getMoveTimerLength(entity) or entity.creatureType.meleeTimerLength
		if not new.timer then
			return
		end
		if not targetEntity then
			return
		end
		new.direction = direction
		new.charge = charge
		local heldItem = self:getHeldItem(entity)
		if heldItem and heldItem.itemType.isMeleeWeapon and heldItem.itemType.meleeTimerAdd then
			new.timer = math.max(1, new.timer + heldItem.itemType.meleeTimerAdd)
		end
		new.targetEntity = targetEntity
		return new
	end
	function melee.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			local ox, oy = self:getDirectionOffset(action.direction)
			local targetX, targetY = entity.x + ox, entity.y + oy
			if action.charge then
				local hitFirstTime
				if self:getAttackStrengths(entity) and action.targetEntity.x == targetX and action.targetEntity.y == targetY then
					local meleeDamage, meleeBleedRateAdd, meleeInstantBloodLoss = self:getAttackStrengths(entity)
					self:damageEntity(action.targetEntity, meleeDamage, entity, meleeBleedRateAdd, meleeInstantBloodLoss)
					hitFirstTime = true
				end
				if canWalkTo(entity, targetX, targetY, true) then
					moveTo(entity, targetX, targetY)
				end
				local hitSecondTime
				if not hitFirstTime and self:getAttackStrengths(entity) and action.targetEntity.x == targetX + ox and action.targetEntity.y == targetY + oy then
					local meleeDamage, meleeBleedRateAdd, meleeInstantBloodLoss = self:getAttackStrengths(entity)
					self:damageEntity(action.targetEntity, meleeDamage, entity, meleeBleedRateAdd, meleeInstantBloodLoss)
					hitSecondTime = true
				end
				if hitFirstTime or hitSecondTime then
					action.doneType = "completed"
				else
					action.replaceAction = move.construct(self, entity, action.direction, "stopCharge")
					action.doneType = "cancelled"
				end
			else
				if self:getAttackStrengths(entity) and action.targetEntity.x == targetX and action.targetEntity.y == targetY then
					local meleeDamage, meleeBleedRateAdd, meleeInstantBloodLoss = self:getAttackStrengths(entity)
					self:damageEntity(action.targetEntity, meleeDamage, entity, meleeBleedRateAdd, meleeInstantBloodLoss)
					action.doneType = "completed"
				else
					action.doneType = "cancelled"
				end
			end
		end
	end
	function melee.fromInput(self, player)
		if not commands.checkCommand("melee") then
			return
		end
		if not player.creatureType.meleeTimerLength then
			return
		end
		local targetEntity = self:getCursorEntity()
		if not targetEntity or targetEntity.entityType ~= "creature" then
			return
		end
		local dx, dy = targetEntity.x - player.x, targetEntity.y - player.y
		if math.abs(dx) > 1 or math.abs(dy) > 1 then
			return
		end
		local direction = self:getDirection(dx, dy)
		if not direction then
			return
		end
		return melee.construct(self, player, targetEntity, direction)
	end

	local pickUp = newActionType("pickUp", "pick up")
	function pickUp.construct(self, entity, targetEntity)
		if not targetEntity then
			return
		end
		if not (targetEntity.entityType == "item" and not targetEntity.itemData.itemType.noPickUp) then
			return
		end
		local freeSlot = self:getBestFreeInventorySlotForItem(entity, targetEntity.itemData)
		if not freeSlot then
			return
		end
		if entity.x ~= targetEntity.x or entity.y ~= targetEntity.y then
			return
		end
		local new = {type = "pickUp"}
		new.timer = 4
		new.targetEntity = targetEntity
		return new
	end
	function pickUp.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			if self:getBestFreeInventorySlotForItem(entity, action.targetEntity.itemData) and action.targetEntity.x == entity.x and action.targetEntity.y == entity.y then
				self:registerPickUp(entity, action.targetEntity)
				action.doneType = "completed"
			else
				action.doneType = "cancelled"
			end
		end
	end
	function pickUp.fromInput(self, player)
		if not (commands.checkCommand("pickUpOrDrop") and not commands.checkCommand("dropMode")) then
			return
		end
		local targetEntity = self:getCursorEntity()
		return pickUp.construct(self, player, targetEntity) -- Can be nil
	end

	local drop = newActionType("drop", "drop")
	function drop.construct(self, entity, direction)
		if not self:getHeldItem(entity) then
			return
		end
		local new = {type = "drop"}
		new.direction = direction
		new.timer = 1
		return new
	end
	function drop.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			local ox, oy = self:getDirectionOffset(action.direction)
			local targetX, targetY = entity.x + ox, entity.y + oy
			local tile = self:getTile(targetX, targetY)
			if entity.inventory and entity.inventory.selectedSlot and not (self:tileBlocksAirMotion(targetX, targetY) or (tile and self.state.tileTypes[tile.type].solidity == "projectilePassable")) then
				self:dropItemFromSlot(entity, entity.inventory.selectedSlot, targetX, targetY)
				action.doneType = "completed"
			else
				action.doneType = "cancelled"
			end
		end
	end
	function drop.fromInput(self, player)
		if not (commands.checkCommand("pickUpOrDrop") and commands.checkCommand("dropMode")) then
			return
		end
		if not self:getHeldItem(player) then
			return
		end
		if not self.state.cursor then
			return
		end
		local x, y = self.state.cursor.x, self.state.cursor.y
		local dx, dy = x - player.x, y - player.y
		if math.abs(dx) > 1 or math.abs(dy) > 1 then
			return
		end
		local direction = self:getDirection(dx, dy)
		if not direction then
			return
		end
		if self:tileBlocksAirMotion(x, y) then
			return
		end
		local tile = self:getTile(x, y)
		if not tile then
			return
		end
		if self:tileBlocksAirMotion(x, y) or (tile and self.state.tileTypes[tile.type].solidity == "projectilePassable") then
			return
		end
		return drop.construct(self, player, direction)
	end

	local useHeldItem = newActionType("useHeldItem", "use item")
	function useHeldItem.construct(self, entity, item, manualCockedStateSelection, energyWeaponModeSet)
		if not self:getHeldItem(entity) or item ~= self:getHeldItem(entity) then
			return
		end
		local itemType = self:getHeldItem(entity).itemType
		if itemType.interactionType and itemType.interactionType.startInfoHeld then
			local new = {type = "useHeldItem"}
			new.item = self:getHeldItem(entity)
			new.timer, new.useInfo = itemType.interactionType.startInfoHeld(self, entity, "held", new.item)
			if not new.timer then
				return
			end
			new.displayNameOverride = new.useInfo and new.useInfo.actionDisplayName
			return new
		elseif self:getHeldItem(entity).itemType.isGun then
			if self:getHeldItem(entity).itemType.energyWeapon then
				local new = {type = "useHeldItem"}
				new.item = self:getHeldItem(entity)
				new.timer = self:getHeldItem(entity).itemType.operationTimerLength
				new.energyWeaponModeSet = energyWeaponModeSet
				return new
			elseif self:getHeldItem(entity).itemType.manuallyOperateCockedStates and manualCockedStateSelection then
				local new = {type = "useHeldItem"}
				new.item = self:getHeldItem(entity)
				new.timer = self:getHeldItem(entity).itemType.manualCockTime
				new.manualCockedStateSelection = manualCockedStateSelection
				return new
			else
				-- Works on automatic too
				local timer = self:getHeldItem(entity).itemType.operationTimerLength
				if not timer then
					return
				end
				if self:getHeldItem(entity).shotCooldownTimer then
					return
				end
				local new = {type = "useHeldItem"}
				new.item = self:getHeldItem(entity)
				new.timer = timer
				return new
			end
		end
	end
	function useHeldItem.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			if not (self:getHeldItem(entity) and self:getHeldItem(entity) == action.item) then
				action.doneType = "cancelled"
				return
			end
			local heldItem = self:getHeldItem(entity)
			local itemType = heldItem.itemType
			if itemType.interactionType then
				action.doneType = "completed"
				if itemType.interactionType.resultHeld then
					local resultInfo = itemType.interactionType.resultHeld(self, entity, "held", heldItem, action.useInfo)
					if resultInfo and resultInfo.deleteInteractee then
						resultInfo.deleteInteractee = nil -- In case we want to return it for some other reason
						self:takeItemFromSlot(entity, entity.inventory.selectedSlot) -- Delete
					end
				end
			elseif itemType.isGun then
				if itemType.energyWeapon then
					heldItem.chargeState = action.energyWeaponModeSet
				elseif itemType.breakAction then
					if heldItem.itemType.manuallyOperateCockedStates and action.manualCockedStateSelection then
						heldItem.cockedStates[action.manualCockedStateSelection] = true
					else
						heldItem.actionOpen = not heldItem.actionOpen
						if heldItem.actionOpen and heldItem.itemType.automaticEjection then
							if heldItem.ejectorStates then
								for i = 1, heldItem.itemType.magazineCapacity do -- Assuming alteredMagazineUse == "select" or whatever
									if heldItem.ejectorStates[i] then
										local ejected = heldItem.magazineData[i]
										heldItem.magazineData[i] = nil
										if ejected then
											self:newItemEntity(entity.x, entity.y, ejected)
										end
									end
								end
							end
							heldItem.ejectorStates = nil
						end
						if not heldItem.actionOpen and heldItem.itemType.cycleOnBreakActionClose then
							self:cycleGun(heldItem, entity.x, entity.y)
						end
					end
				else
					self:cycleGun(heldItem, entity.x, entity.y)
				end
				action.doneType = "completed"
			else
				-- Do nothing, I guess
				action.doneType = "completed"
			end
		end
	end
	function useHeldItem.fromInput(self, player)
		if commands.checkCommand("useHeldItem") then
			local manualCockedStateSelection
			if commands.checkCommand("operateBarrel1") and commands.checkCommand("operateBarrel2") then

			elseif commands.checkCommand("operateBarrel1") then
				manualCockedStateSelection = 1
			elseif commands.checkCommand("operateBarrel2") then
				manualCockedStateSelection = 2
			end
			local energyWeaponModeSet = "hold"
			if commands.checkCommand("energyWeaponChargeMode") and not commands.checkCommand("energyWeaponDischargeMode") then
				energyWeaponModeSet = "fromBattery"
			elseif commands.checkCommand("energyWeaponDischargeMode") then
				energyWeaponModeSet = "toBattery"
			end
			return useHeldItem.construct(self, player, self:getHeldItem(player), manualCockedStateSelection, energyWeaponModeSet) -- Can be nil
		end
	end

	local swapInventorySlot = newActionType("swapInventorySlot", "swap slot")
	function swapInventorySlot.construct(self, entity, slot)
		if entity.inventory and (not slot or (#entity.inventory >= slot and entity.inventory[slot].item)) and slot ~= entity.inventory.selectedSlot then
			local new = {type = "swapInventorySlot"}
			new.slot = slot
			new.timer = 8
			return new
		end
	end
	function swapInventorySlot.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			if entity.inventory and (not action.slot or (#entity.inventory >= action.slot and entity.inventory[action.slot].item)) then
				entity.inventory.selectedSlot = action.slot
				action.doneType = "completed"
			else
				action.doneType = "cancelled"
			end
		end
	end
	function swapInventorySlot.fromInput(self, player)
		if not player.inventory then
			return
		end
		if commands.checkCommand("unloadMode") or commands.checkCommand("changeWornItemMode") then
			return
		end
		if commands.checkCommand("deselectInventorySlot") then
			return swapInventorySlot.construct(self, player, nil)
		elseif not commands.checkCommand("reloadMode") then
			for i = 1, 9 do
				if i > #player.inventory then
					break
				end
				if not player.inventory[i].item then
					goto continue
				end
				if commands.checkCommand("handleInventorySlot" .. i) then
					return swapInventorySlot.construct(self, player, i)
				end
			    ::continue::
			end
		end
	end

	local reload = newActionType("reload", "reload")
	function reload.validate(self, entity, action)
		if not entity.inventory then
			return
		end
		local heldItem = self:getHeldItem(entity)
		if not heldItem then
			return
		end
		local reloadItem = entity.inventory[action.slot].item
		if not reloadItem then
			return
		end
		if heldItem.itemType.breakAction and not heldItem.actionOpen then
			return false
		end
		if action.reloadType == "replaceMagazine" then
			if
				not heldItem.insertedMagazine and
				heldItem.itemType.magazineRequired and
				(reloadItem.itemType.magazine or reloadItem.itemType.energyBattery) and not reloadItem.itemType.isGun and
				heldItem.itemType.magazineClass == reloadItem.itemType.magazineClass
			then
				return true
			end
		elseif action.reloadType == "addRoundToMagazineData" then
			local spaceFree
			if heldItem.itemType.alteredMagazineUse == "select" then
				if not action.magazineSlotSelectionIndex then
					return false
				end
				spaceFree = not heldItem.magazineData[action.magazineSlotSelectionIndex]
			else
				spaceFree = #heldItem.magazineData < heldItem.itemType.magazineCapacity
			end
			if
				heldItem.itemType.magazine and
				reloadItem.itemType.isAmmo and
				heldItem.itemType.ammoClass == reloadItem.itemType.ammoClass and
				spaceFree
			then
				return true
			end
		end
		return false
	end
	function reload.construct(self, entity, slot, reloadType, magazineSlotSelectionIndex)
		local new = {type = "reload"}
		new.slot = slot
		new.reloadType = reloadType
		new.timer = 12
		new.magazineSlotSelectionIndex = magazineSlotSelectionIndex
		if reload.validate(self, entity, new) then
			return new
		end
	end
	function reload.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			if reload.validate(self, entity, action) then
				local heldItem = self:getHeldItem(entity)
				local item = self:takeItemFromSlot(entity, action.slot)
				if action.reloadType == "replaceMagazine" then
					heldItem.insertedMagazine = item
				elseif action.reloadType == "addRoundToMagazineData" then
					if heldItem.itemType.alteredMagazineUse == "select" then
						heldItem.magazineData[action.magazineSlotSelectionIndex] = item
					else
						table.insert(heldItem.magazineData, item)
					end
				end
				action.doneType = "completed"
			else
				action.doneType = "cancelled"
			end
		end
	end
	function reload.fromInput(self, player)
		local heldItem = self:getHeldItem(player)
		if not heldItem then
			return
		end
		if not commands.checkCommand("reloadMode") then
			return
		end
		if not player.inventory then
			return
		end
		local number
		for i = 1, 9 do
			if i > #player.inventory then
				break
			end
			if commands.checkCommand("handleInventorySlot" .. i) then
				number = i
			end
		end
		if not number then
			return
		end

		if heldItem.itemType.magazine then
			local selection
			if heldItem.itemType.alteredMagazineUse == "select" then
				if commands.checkCommand("operateBarrel1") and commands.checkCommand("operateBarrel2") then

				elseif commands.checkCommand("operateBarrel1") then
					selection = 1
				elseif commands.checkCommand("operateBarrel2") then
					selection = 2
				else
					-- Try cocked barrels (so that the gun is immediately ready to fire) first
					for i = 1, heldItem.itemType.magazineCapacity do
						if not heldItem.magazineData[i] and heldItem.cockedStates[i] then
							selection = i
							break
						end
					end
					-- Go into first empty barrel
					if not selection then
						for i = 1, heldItem.itemType.magazineCapacity do
							if not heldItem.magazineData[i] then
								selection = i
								break
							end
						end
					end
				end
				if not selection then
					return nil
				end
			end
			return reload.construct(self, player, number, "addRoundToMagazineData", selection) -- If valid
		elseif heldItem.itemType.magazineRequired then
			return reload.construct(self, player, number, "replaceMagazine") -- If valid
		end
	end

	local unload = newActionType("unload", "unload")
	function unload.validate(self, entity, action)
		local heldItem = self:getHeldItem(entity)
		if not heldItem then
			return false
		end
		if not (heldItem.magazineData or heldItem.insertedMagazine) then
			return false
		end
		if heldItem.itemType.breakAction and not heldItem.actionOpen then
			return false
		end
		local selectType = heldItem.itemType.alteredMagazineUse == "select"
		if heldItem.magazineData and not selectType then
			if #heldItem.magazineData == 0 then
				return false
			end
		end
		local itemToUnload
		if heldItem.itemType.magazine then
			if selectType then
				if not action.magazineSlotSelectionIndex then
					return false
				end
				itemToUnload = heldItem.magazineData[action.magazineSlotSelectionIndex]
			else
				itemToUnload = heldItem.magazineData[#heldItem.magazineData]
			end
		else
			itemToUnload = heldItem.insertedMagazine
		end
		if not itemToUnload then
			return false
		end
		if action.slot then
			if not (
				entity.inventory and
				entity.inventory[action.slot] and
				(
					not entity.inventory[action.slot].item or
					(
						self:isItemStackable(entity.inventory[action.slot].item, itemToUnload) and
						self:getSlotStackSize(entity, action.slot) < self:getMaxStackSize(entity.inventory[action.slot].item)
					)
				)
			) then
				return false
			end
		else
			local ox, oy = self:getDirectionOffset(action.direction)
			local targetX, targetY = entity.x + ox, entity.y + oy
			if self:tileBlocksAirMotion(targetX, targetY) then
				return false
			end
		end
		return true
	end
	function unload.construct(self, entity, slot, floorX, floorY, magazineSlotSelectionIndex)
		local new = {type = "unload"}
		if slot then
			new.slot = slot
		else
			new.direction = self:getDirection(floorX - entity.x, floorY - entity.y)
		end
		new.magazineSlotSelectionIndex = magazineSlotSelectionIndex
		new.timer = 9
		if unload.validate(self, entity, new) then
			return new
		end
	end
	function unload.process(self, entity, action)
		action.timer = action.timer - 1
		if not unload.validate(self, entity, action) then
			action.doneType = "cancelled"
			return
		end
		if action.timer <= 0 then
			local heldItem = self:getHeldItem(entity)
			local unloadedItem
			if heldItem.itemType.magazine then
				if heldItem.itemType.alteredMagazineUse == "select" then
					unloadedItem = heldItem.magazineData[action.magazineSlotSelectionIndex]
					heldItem.magazineData[action.magazineSlotSelectionIndex] = nil
				else
					unloadedItem = table.remove(heldItem.magazineData)
				end
			else
				unloadedItem = heldItem.insertedMagazine
				heldItem.insertedMagazine = nil
			end
			if action.slot then
				local added = self:addItemToSlot(entity, action.slot, unloadedItem)
				assert(added, "Couldn't add item to slot for unload action, even though the action was(?) validated")
			else
				local ox, oy = self:getDirectionOffset(action.direction)
				local targetX, targetY = entity.x + ox, entity.y + oy
				self:newItemEntity(targetX, targetY, unloadedItem)
			end
			action.doneType = "completed"
		end
	end
	function unload.fromInput(self, player)
		if not commands.checkCommand("unloadMode") then
			return
		end
		local heldItem = self:getHeldItem(player)
		if not heldItem then
			return
		end
		if not player.inventory then
			return
		end

		local magIndex
		if self:getHeldItem(player).itemType.alteredMagazineUse == "select" then
			if commands.checkCommand("operateBarrel1") and commands.checkCommand("operateBarrel2") then

			elseif commands.checkCommand("operateBarrel1") then
				magIndex = 1
			elseif commands.checkCommand("operateBarrel2") then
				magIndex = 2
			else
				-- Unload fired ones in cocked barrels first, so that you can reload into a cocked barrel quickly
				for i = 1, self:getHeldItem(player).itemType.magazineCapacity do
					if self:getHeldItem(player).magazineData[i] and self:getHeldItem(player).magazineData[i].fired and self:getHeldItem(player).cockedStates[i] then
						magIndex = i
						break
					end
				end
				-- Try unloading fired barrels, cocked or otherwise
				if not magIndex then
					for i = 1, self:getHeldItem(player).itemType.magazineCapacity do
						if self:getHeldItem(player).magazineData[i] and self:getHeldItem(player).magazineData[i].fired then
							magIndex = i
							break
						end
					end
				end
				-- Just try unloading the first round found
				if not magIndex then
					for i = 1, self:getHeldItem(player).itemType.magazineCapacity do
						if self:getHeldItem(player).magazineData[i] then
							magIndex = i
							break
						end
					end
				end
			end
			if not magIndex then
				return nil
			end
		end

		if commands.checkCommand("deselectInventorySlot") then
			local x, y
			if not self.state.cursor then
				x, y = player.x, player.y
			else
				x, y = self.state.cursor.x, self.state.cursor.y
				local dx, dy = x - player.x, y - player.y
				if math.abs(dx) > 1 or math.abs(dy) > 1 then
					-- return
					x, y = player.x, player.y
				end
			end
			return unload.construct(self, player, nil, x, y, magIndex)
		end

		local number
		for i = 1, 9 do
			if i > #player.inventory then
				break
			end
			if commands.checkCommand("handleInventorySlot" .. i) then
				number = i
			end
		end
		if not number then
			return
		end
		return unload.construct(self, player, number, nil, nil, magIndex)
	end

	local interact = newActionType("interact", "interact")
	function interact.construct(self, entity, targetEntity, direction)
		if not targetEntity then
			return
		end
		if not (targetEntity.entityType == "item" and targetEntity.itemData.itemType.interactable) then
			return
		end
		local new = {type = "interact"}
		new.direction = direction
		if not (targetEntity.itemData.itemType.interactionType and targetEntity.itemData.itemType.interactionType.startInfoWorld) then
			return
		end
		new.timer, new.useInfo = targetEntity.itemData.itemType.interactionType.startInfoWorld(self, entity, "world", targetEntity)
		new.displayNameOverride = new.useInfo and new.useInfo.actionDisplayName
		if not new.timer then
			return
		end
		new.targetEntity = targetEntity
		return new
	end
	function interact.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			local ox, oy = self:getDirectionOffset(action.direction)
			local targetX, targetY = entity.x + ox, entity.y + oy
			if action.targetEntity.x == targetX and action.targetEntity.y == targetY then
				action.doneType = "completed"
				if action.targetEntity.itemData.itemType.interactionType and action.targetEntity.itemData.itemType.interactionType.resultWorld then
					local resultInfo = action.targetEntity.itemData.itemType.interactionType.resultWorld(self, entity, "world", action.targetEntity, action.useInfo)
					return resultInfo -- processActions has special handling
				end
			else
				action.doneType = "cancelled"
			end
		end
	end
	function interact.fromInput(self, player)
		if not commands.checkCommand("interact") then
			return
		end
		local targetEntity = self:getCursorEntity()
		if not targetEntity or targetEntity.entityType ~= "item" or not targetEntity.itemData.itemType.interactable then
			return
		end
		local dx, dy = targetEntity.x - player.x, targetEntity.y - player.y
		if math.abs(dx) > 1 or math.abs(dy) > 1 then
			return
		end
		local direction = self:getDirection(dx, dy)
		if not direction then
			return
		end
		return interact.construct(self, player, targetEntity, direction)
	end

	local mindAttack = newActionType("mindAttack", "mind flay")
	function mindAttack.validate(self, entity, action)
		if not entity.creatureType.telepathicMindAttackDamageRate then
			return false
		end
		if not (action.target and not action.target.dead) then
			return false
		end
		if not self:entityCanSeeEntity(entity, action.target) then
			return false
		end
		return true
	end
	function mindAttack.construct(self, entity, target)
		local new = {type = "mindAttack"}
		new.timer = 1
		new.target = target
		if mindAttack.validate(self, entity, new) then
			return new
		end
	end
	function mindAttack.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			if mindAttack.validate(self, entity, action) then
				if action.target.creatureType.psychicDamageDeathPoint then
					action.target.psychicDamage = (action.target.psychicDamage or 0) + entity.creatureType.telepathicMindAttackDamageRate
					action.target.psychicDamageTakenThisTick = (action.target.psychicDamageTakenThisTick or 0) + entity.creatureType.telepathicMindAttackDamageRate
				end
				action.doneType = "completed"
			else
				action.doneType = "cancelled"
			end
		end
	end

	local doffItem = newActionType("doffItem", "doff item")
	function doffItem.validate(self, entity, action)
		local itemToDoff = entity.currentWornItem
		if not itemToDoff then
			return false
		end
		if action.slot then
			if not (
				entity.inventory and
				entity.inventory[action.slot] and
				(
					not entity.inventory[action.slot].item or
					(
						self:isItemStackable(entity.inventory[action.slot].item, itemToDoff) and
						self:getSlotStackSize(entity, action.slot) < self:getMaxStackSize(entity.inventory[action.slot].item)
					)
				)
			) then
				return false
			end
		else
			local ox, oy = self:getDirectionOffset(action.direction)
			local targetX, targetY = entity.x + ox, entity.y + oy
			if self:tileBlocksAirMotion(targetX, targetY) then
				return false
			end
		end
		return true
	end
	function doffItem.construct(self, entity, slot, floorX, floorY)
		local new = {type = "doffItem"}
		if slot then
			new.slot = slot
		else
			new.direction = self:getDirection(floorX - entity.x, floorY - entity.y)
		end
		new.timer = 40
		if doffItem.validate(self, entity, new) then
			return new
		end
	end
	function doffItem.process(self, entity, action)
		action.timer = action.timer - 1
		if not doffItem.validate(self, entity, action) then
			action.doneType = "cancelled"
			return
		end
		if action.timer <= 0 then
			local doffedItem = entity.currentWornItem
			entity.currentWornItem = nil
			if action.slot then
				local added = self:addItemToSlot(entity, action.slot, doffedItem)
				assert(added, "Couldn't add item to slot for doff item action, even though the action was(?) validated")
			else
				local ox, oy = self:getDirectionOffset(action.direction)
				local targetX, targetY = entity.x + ox, entity.y + oy
				self:newItemEntity(targetX, targetY, doffedItem)
			end
			action.doneType = "completed"
		end
	end
	function doffItem.fromInput(self, player)
		if not commands.checkCommand("changeWornItemMode") then
			return
		end

		if commands.checkCommand("deselectInventorySlot") then
			local x, y
			if not self.state.cursor then
				x, y = player.x, player.y
			else
				x, y = self.state.cursor.x, self.state.cursor.y
				local dx, dy = x - player.x, y - player.y
				if math.abs(dx) > 1 or math.abs(dy) > 1 then
					-- return
					x, y = player.x, player.y
				end
			end
			return doffItem.construct(self, player, nil, x, y)
		end

		local number
		for i = 1, 9 do
			if i > #player.inventory then
				break
			end
			if commands.checkCommand("handleInventorySlot" .. i) then
				number = i
			end
		end
		if not number then
			return
		end
		return doffItem.construct(self, player, number, nil, nil)
	end

	local donItem = newActionType("donItem", "don item")
	function donItem.validate(self, entity, action)
		if not entity.inventory then
			return false
		end
		local heldItem = self:getHeldItem(entity)
		if not heldItem then
			return false
		end
		if not heldItem.itemType.wearable then
			return false
		end
		if entity.currentWornItem then
			return false
		end
		return true
	end
	function donItem.construct(self, entity)
		local new = {type = "donItem"}
		new.timer = 40
		if donItem.validate(self, entity, new) then
			return new
		end
	end
	function donItem.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			if donItem.validate(self, entity, action) then
				entity.currentWornItem = self:takeItemFromSlot(entity, entity.inventory.selectedSlot)
				action.doneType = "completed"
			else
				action.doneType = "cancelled"
			end
		end
	end
	function donItem.fromInput(self, player)
		if not commands.checkCommand("changeWornItemMode") then
			return
		end
		return donItem.construct(self, player) -- If valid
	end
end

return game
