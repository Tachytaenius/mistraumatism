local game = {}

function game:getSoundHeard(entity, eventData)
	if not eventData.soundRange then
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
	local eventType = self.state.eventTypes[eventData.type]
	if not eventType.announceToPlayer then
		return
	end
	local isPlayer = eventData.sourceEntity == player
	local sourceKnown = isPlayer or (
		eventType.sourceEntityRelation ~= "remoteCause" and
		eventData.sourceEntity and (visible or eventType.audioRevealsSource and audible)
	)
	local text, colour = eventType.announceToPlayer(
		self, eventData, isPlayer, sourceKnown, visible, audible
	)
	if text then
		self:announce(text, colour)
	end
end

function game:broadcastEvent(eventData)
	local state = self.state
	assert(state.eventTypes[eventData.type], "Unknown event type " .. eventData.type)
	state.eventsQueue[#state.eventsQueue+1] = eventData
end

function game:handleEventsQueue()
	local state = self.state
	local builtUpEventsQueue = state.eventsQueue
	state.eventsQueue = {} -- Accumulate anything for next tick
	for _, eventData in ipairs(builtUpEventsQueue) do
		local handledEntities = {}
		local function handleEntity(entity, direct)
			if handledEntities[entity] then
				return
			end
			handledEntities[entity] = true

			if entity == state.player then -- Allowed if entity is source entity
				local visible = self:entityCanSeeTile(entity, eventData.x, eventData.y)
				local audible = self:getSoundHeard(entity, eventData)
				if direct or visible or audible then
					self:handleEventForPlayer(eventData, visible, audible)
				end
				return
			end

			if eventData.sourceEntity == entity then
				return
			end
			if entity.entityType ~= "creature" or entity.dead then
				return
			end

			local visible = self:entityCanSeeTile(entity, eventData.x, eventData.y)
			local audible = self:getSoundHeard(entity, eventData)
			if direct or visible or audible then
				self:tryInvestigateEvent(entity, eventData, visible, audible)
			end
		end

		if state.player and eventData.sourceEntity == state.player and state.eventTypes[eventData.type].sourceEntityRelation ~= "remoteCause" then
			-- If an event happens about an entity's person, the entity should automatically know about it. This also skips death checks for the player.
			handleEntity(state.player, true)
		end

		if eventData.directSignalEntities then
			for _, entity in ipairs(eventData.directSignalEntities) do
				handleEntity(entity, true)
			end
		end

		if not eventData.directSignalOnly then
			for _, entity in ipairs(state.entities) do
				handleEntity(entity, false)
			end
		end
	end
end

return game
