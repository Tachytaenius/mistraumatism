local commands = require("commands")
local consts = require("consts")

local game = {}

-- TODO: Action validatation
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

	local move = newActionType("move", "move")
	function move.construct(self, entity, direction)
		local moveTimerLength = entity.creatureType.moveTimerLength
		if not moveTimerLength then
			return
		end
		local new = {type = "move"}
		assert(direction ~= "zero", "Move action should not use the zero direction")
		new.direction = direction
		local multiplier = self:isDirectionDiagonal(direction) and consts.inverseDiagonal or 1
		new.timer = math.floor(moveTimerLength * multiplier)
		return new
	end
	function move.process(self, entity, action)
		local destinationX, destinationY = self:getDestinationTile(entity)
		if self:getWalkable(destinationX, destinationY) then
			action.timer = action.timer - 1
			if action.timer <= 0 then
				entity.x, entity.y = destinationX, destinationY
				action.doneType = "completed"
				return
			end
		else
			action.doneType = "cancelled"
		end
	end
	function move.fromInput(self, player)
		local playerMoveTimerLength = player.creatureType.moveTimerLength
		if playerMoveTimerLength then
			local direction
			if not commands.checkCommand("moveCursor") then
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
				if self:getWalkable(player.x + offsetX, player.y + offsetY) then
					return move.construct(self, player, direction)
				end
			end
		end
	end

	local shoot = newActionType("shoot", "shoot")
	function shoot.construct(self, entity, targetX, targetY, targetEntity, shotType, abilityName)
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
				self:shootGun(entity, action, self:getHeldItem(entity), targetEntity)
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
		local cursor = self.state.cursor
		if not cursor then
			return
		end
		return shoot.construct(self, player, cursor.x, cursor.y, self:getCursorEntity())
	end

	local melee = newActionType("melee", "melee")
	function melee.construct(self, entity, targetEntity, direction)
		if not entity.creatureType.meleeTimerLength then
			return
		end
		if not targetEntity then
			return
		end
		local new = {type = "melee"}
		new.direction = direction
		new.timer = entity.creatureType.meleeTimerLength
		new.targetEntity = targetEntity
		return new
	end
	function melee.process(self, entity, action)
		action.timer = action.timer - 1
		if action.timer <= 0 then
			local ox, oy = self:getDirectionOffset(action.direction)
			local targetX, targetY = entity.x + ox, entity.y + oy
			if self:getAttackStrengths(entity) and action.targetEntity.x == targetX and action.targetEntity.y == targetY then
				local meleeDamage, meleeBleedRateAdd, meleeInstantBloodLoss = self:getAttackStrengths(entity)
				self:damageEntity(action.targetEntity, meleeDamage, entity, meleeBleedRateAdd, meleeInstantBloodLoss)
				action.doneType = "completed"
			else
				action.doneType = "cancelled"
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
		local freeSlot = self:getFirstFreeInventorySlotForItem(entity, targetEntity.itemData)
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
			if self:getFirstFreeInventorySlotForItem(entity, action.targetEntity.itemData) and action.targetEntity.x == entity.x and action.targetEntity.y == entity.y then
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
			if entity.inventory and entity.inventory.selectedSlot and not self:tileBlocksAirMotion(targetX, targetY) then
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
		return drop.construct(self, player, direction)
	end

	local useHeldItem = newActionType("useHeldItem", "use item")
	function useHeldItem.construct(self, entity, item)
		if not self:getHeldItem(entity) or item ~= self:getHeldItem(entity) then
			return
		end
		local itemType = self:getHeldItem(entity).itemType
		if itemType.interactionType then
			local new = {type = "useHeldItem"}
			new.item = self:getHeldItem(entity)
			new.timer, new.useInfo = itemType.interactionType.startInfoHeld(self, entity, "held", new.item)
			if not new.timer then
				return
			end
			return new
		elseif self:getHeldItem(entity).itemType.isGun then
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
				itemType.interactionType.resultHeld(self, entity, "held", heldItem, action.useInfo)
				action.doneType = "completed"
			elseif itemType.isGun then
				self:cycleGun(heldItem, entity.x, entity.y)
				action.doneType = "completed"
			else
				-- Do nothing, I guess
				action.doneType = "completed"
			end
		end
	end
	function useHeldItem.fromInput(self, player)
		if commands.checkCommand("useHeldItem") then
			return useHeldItem.construct(self, player, self:getHeldItem(player)) -- Can be nil
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
		if commands.checkCommand("unloadMode") then
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
		if action.reloadType == "replaceMagazine" then
			if
				not heldItem.insertedMagazine and
				heldItem.itemType.magazineRequired and
				reloadItem.itemType.magazine and not reloadItem.itemType.isGun and
				heldItem.itemType.magazineClass == reloadItem.itemType.magazineClass
			then
				return true
			end
		elseif action.reloadType == "addRoundToMagazineData" then
			if
				heldItem.itemType.magazine and
				reloadItem.itemType.isAmmo and
				heldItem.itemType.ammoClass == reloadItem.itemType.ammoClass and
				#heldItem.magazineData < heldItem.itemType.magazineCapacity
			then
				return true
			end
		end
		return false
	end
	function reload.construct(self, entity, slot, reloadType, alt)
		local new = {type = "reload"}
		new.slot = slot
		new.reloadType = reloadType
		new.alt = alt -- For double barrel etc
		new.timer = 12
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
					table.insert(heldItem.magazineData, item)
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
			return reload.construct(self, player, number, "addRoundToMagazineData") -- If valid
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
		if heldItem.magazineData then
			if #heldItem.magazineData == 0 then
				return false
			end
		end
		if action.slot then
			local itemToUnload
			if heldItem.itemType.magazine then
				itemToUnload = heldItem.magazineData[#heldItem.magazineData]
			else
				itemToUnload = heldItem.insertedMagazine
			end
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
	function unload.construct(self, entity, slot, floorX, floorY)
		local new = {type = "unload"}
		if slot then
			new.slot = slot
		else
			new.direction = self:getDirection(floorX - entity.x, floorY - entity.y)
		end
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
				unloadedItem = table.remove(heldItem.magazineData)
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

		if commands.checkCommand("deselectInventorySlot") then
			if not self.state.cursor then
				return
			end
			local x, y = self.state.cursor.x, self.state.cursor.y
			local dx, dy = x - player.x, y - player.y
			if math.abs(dx) > 1 or math.abs(dy) > 1 then
				return
			end
			return unload.construct(self, player, nil, x, y)
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
		return unload.construct(self, player, number)
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
		new.timer, new.interactionIntent = targetEntity.itemData.itemType.interactionType.startInfoWorld(self, entity, "world", targetEntity)
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
				if action.targetEntity.itemData.itemType.interactionType then
					action.targetEntity.itemData.itemType.interactionType.resultWorld(self, entity, "world", action.targetEntity, action.interactionIntent)
				end
				action.doneType = "completed"
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
end

return game
