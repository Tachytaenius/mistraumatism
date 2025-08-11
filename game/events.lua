local game = {}

function game:getSoundHeard(entity, eventData)
	if not (eventData.soundType and eventData.soundRange) then
		return false
	end
	if not entity.creatureType.hears then
		return false
	end
	return self:distance(eventData.x, eventData.y, entity.x, entity.y) <= eventData.soundRange
end

function game:handleEventForPlayer(eventData, visible, audible)
	local player = self.state.player
	if not player then
		return
	end
	-- TODO (or not!): Filter out player-made events that don't need to be announced
	self:announce("(TODO) Event: " .. eventData.type .. ", " .. (audible and eventData.soundType or "???") .. ", " .. (eventData.sourceEntity and eventData.sourceEntity.creatureType.displayName or "???"), "lightGrey")
end

function game:broadcastEvent(eventData)
	-- For an event with sound, eventData.sourceEntity isn't always vocalising the sound. Especially if x and y aren't the entity's x and y
	local state = self.state
	state.eventsQueue[#state.eventsQueue+1] = eventData
end

function game:handleEventsQueue()
	local state = self.state
	local builtUpEventsQueue = state.eventsQueue
	state.eventsQueue = {} -- Accumulate anything for next tick
	for _, eventData in ipairs(builtUpEventsQueue) do
		for _, entity in ipairs(state.entities) do
			if entity == state.player then -- Allowed if entity is source entity
				-- No events will be seen/heard when dead
				local visible = self:entityCanSeeTile(entity, eventData.x, eventData.y)
				local audible = self:getSoundHeard(entity, eventData)
				if visible or audible then
					self:handleEventForPlayer(eventData, visible, audible)
				end
				goto continue
			end
			if eventData.sourceEntity == entity then
				goto continue
			end
			if entity.entityType ~= "creature" or entity.dead then
				goto continue
			end
			local visible = self:entityCanSeeTile(entity, eventData.x, eventData.y)
			local audible = self:getSoundHeard(entity, eventData)
			if visible or audible then
				self:tryInvestigateEvent(entity, eventData, visible, audible)
			end
			::continue::
		end
	end
end

function game:loadEventTypes()
	local eventTypes = {}
	self.state.eventTypes = eventTypes

	-- sourceEntityRelation describes the meaning of the sourceEntity:
	-- self: the event was done directly by the source entity (such as a vocalisation or a point). Such as a scream.
	-- objectUse: the event was done by the source entity doing something to something else. Such as a gunshot.
	-- remoteCause: the event was caused by the entity but not physically using the entity's body or an object. eventData x and y would probably be different to the source entity's position.
	-- doneTo: the event was done to the source entity.

	eventTypes.doorChangeState = {
		sourceEntityRelation = "objectUse"
	}

	eventTypes.pain = {
		isDamageTaken = true,
		isCombat = true,
		sourceEntityRelation = "self"
	}
	eventTypes.enemyAlert = {
		isCombat = true,
		investigateLocationOverride = "spottedEntityLocation",
		sourceEntityRelation = "self"
	}
	eventTypes.gunshot = {
		isAttack = true,
		isCombat = true,
		sourceEntityRelation = "objectUse"
	}
	eventTypes.explosion = {
		isAttack = true,
		isCombat = true,
		sourceEntityRelation = "remoteCause"
		-- investigateLocationOverride = "explosionLocation" -- No need, the explosion event broadcast has x and y set to the explosion's location
	}
	eventTypes.gibbing = {
		isDamageTaken = true,
		isCombat = true,
		sourceEntityRelation = "doneTo"
	}
end

function game:loadSoundTypes()
	local soundTypes = {}
	self.state.soundTypes = soundTypes

	soundTypes.gunshot = {}
	soundTypes.warcry = {}
	soundTypes.scream = {}
	soundTypes.deathScream = {}
	soundTypes.goreExplosion = {}
	soundTypes.boneExplosion = {}
	soundTypes.explosion = {}
	soundTypes.doorOpening = {}
	soundTypes.doorClosing = {}
end

return game
