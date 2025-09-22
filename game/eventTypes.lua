local util = require("util")

local game = {}

function game:loadEventTypes()
	local eventTypes = {}
	self.state.eventTypes = eventTypes

	-- sourceEntityRelation describes the meaning of the sourceEntity:
	-- self: the event was done directly by the source entity. Such as a vocalisation or a point.
	-- objectUse: the event was done by the source entity doing something to something else. Such as a gunshot.
	-- remoteCause: the event was caused by the entity but not physically using the entity's body or an object. eventData x and y would probably be different to the source entity's position.
	-- doneTo: the event was done to the source entity.

	-- NOTE: (At time of writing) audioRevealsSource only works if sourceEntityRelation is not remoteCause

	-- NOTE: Be sure to use state.playerBeforeRemoval instead of state.player since events propagate to the player even if they've been destroyed

	local function announceVerbObject(eventData, playerSource, sourceKnown, visible, audible, verb, verbs, an, object)
		if playerSource then
			return "You " .. verb .. " the " .. object .. ".", "darkGrey"
		elseif sourceKnown then
			return "The " .. self:getEntityDisplayName(eventData.sourceEntity) .. " " .. verbs .. " the " .. object .. ".", "darkGrey"
		elseif visible then
			return "You see " .. (an and "an " or "a ") .. object .. " " .. verb .. ".", "darkGrey"
		elseif audible then
			return "You hear " .. (an and "an " or "a ") .. object .. " " .. verb .. ".", "darkGrey"
		end
	end
	local function makeSimpleStateToggleAnnouncer(an, object, eventDataStateKey, trueVerb, trueVerbs, falseVerb, falseVerbs)
		local announceToPlayer = function(self, eventData, playerSource, sourceKnown, visible, audible)
			local state = eventData[eventDataStateKey]
			return announceVerbObject(
				eventData, playerSource, sourceKnown, visible, audible,
				state and trueVerb or falseVerb,
				state and trueVerbs or falseVerbs,
				an, object
			)
		end
		return announceToPlayer
	end
	eventTypes.doorChangeState = {
		sourceEntityRelation = "objectUse",
		announceToPlayer = makeSimpleStateToggleAnnouncer(false, "door", "wasOpening", "open", "opens", "close", "closes")
	}
	eventTypes.hatchChangeState = {
		sourceEntityRelation = "objectUse",
		announceToPlayer = makeSimpleStateToggleAnnouncer(false, "hatch", "wasOpening", "open", "opens", "shut", "shuts")
	}
	eventTypes.buttonChangeState = {
		sourceEntityRelation = "objectUse",
		announceToPlayer = makeSimpleStateToggleAnnouncer(false, "button", "wasPressing", "press", "presses", "reset", "resets")
	}
	eventTypes.leverChangeState = {
		announceToPlayer = makeSimpleStateToggleAnnouncer(false, "lever", "wasActivating", "activate", "activates", "deactivate", "deactivates")
	}

	eventTypes.damageReceived = {
		isDamageTaken = true,
		isCombat = true,
		sourceEntityRelation = "doneTo",
		announceToPlayer = function(self, eventData, playerSource, sourceKnown, visible, audible)
			-- damageDealer is damage source
			-- sourceEntity is damage receiver (source of the event)

			local player = self.state.playerBeforeRemoval

			local dealerKnown = false
			local dealtByNonEntity = type(eventData.damageDealer) ~= "table"
			if eventData.damageDealer then
				dealerKnown = dealtByNonEntity or self:entityCanSeeEntity(player, eventData.damageDealer)
			end
			local grammarHits -- "hits" as opposed to "hit"
			local dealerName
			if dealerKnown then
				if player and eventData.damageDealer == player then
					dealerName = "you"
					grammarHits = false
				elseif dealtByNonEntity then
					-- TODO: Extra control over grammar
					dealerName = self.state.damageSourceTypes[eventData.damageDealer].displayName
					grammarHits = true
				else
					dealerName = "the " .. self:getEntityDisplayName(eventData.damageDealer)
					grammarHits = true
				end
			else
				dealerName = "something"
				grammarHits = true
			end

			local receiverName
			if sourceKnown then
				local living =
					not eventData.sourceEntity.dead or
					eventData.sourceEntity.deathTick == self.state.tick
				if playerSource then
					receiverName =
						player and eventData.damageDealer == player and
						(living and "yourself" or "your own corpse") or
						(living and "you" or "your corpse")
				else
					receiverName = (living and "the " or "the dead ") .. self:getEntityDisplayName(eventData.sourceEntity)
				end
			else
				receiverName = "something"
			end

			local damage = eventData.damageDealt
			local damageKnown = visible

			local outColour, punctuation
			if playerSource then
				outColour = "red"
				punctuation = "!"
			elseif player and player == eventData.damageDealer then
				outColour = "cyan"
				punctuation = "!"
			else
				outColour = "lightGrey"
				punctuation = "."
			end

			local outText =
				dealerName ..
				(grammarHits and " hits " or " hit ") ..
				receiverName ..
				(damageKnown and (" for " .. damage .. " damage") or "") ..
				punctuation

			return util.capitalise(outText, false), outColour
		end
	}
	local deathTexts = {
		fell = "fallen into a pit",
		bledOut = "bled out",
		drowned = "drowned",
		airDrowned = "air-drowned",
		struckDown = "been killed",
		psychicDamage = "faded away"
	}
	eventTypes.death = {
		isDamageTaken = true,
		isCombat = true,
		sourceEntityRelation = "doneTo",
		announceToPlayer = function(self, eventData, playerSource, sourceKnown, visible, audible)
			local textStart
			local colour, punctuation
			if eventData.wasPlayer then
				textStart = "You have "
				colour = "red"
				punctuation = "."
			elseif sourceKnown then
				textStart = "The " .. self:getEntityDisplayName(eventData.sourceEntity) .. " has "
				colour = "cyan"
				punctuation = "."
			else
				textStart = "Something has "
				colour = "lightGrey"
				punctuation = "."
			end

			local deathText = eventData.deathCause and deathTexts[eventData.deathCause] or "has died"

			return textStart .. deathText .. punctuation, colour
		end
	}
	eventTypes.pain = {
		isDamageTaken = true,
		isCombat = true,
		sourceEntityRelation = "self",
		audioRevealsSource = true,
		announceToPlayer = function(self, eventData, playerSource, sourceKnown, visible, audible)
			local a, b
			if eventData.isDeath then
				if eventData.painSound == "scream" then
					a = "lets out a dying wail"
					b = "let out a dying wail"
				else
					a = "gives in to pain"
					b = "give in to pain"
				end
			else
				if eventData.painSound == "scream" then
					a = "screams in pain"
					b = "scream in pain"
				else
					a = "flinches in pain"
					b = "flinch in pain"
				end
			end

			if playerSource then
				return "You " .. b .. ".", "darkRed"
			elseif sourceKnown then
				return "The " .. self:getEntityDisplayName(eventData.sourceEntity) .. " " .. a .. ".", "darkCyan"
			elseif visible then
				return "You see something " .. b .. ".", "darkGrey"
			elseif audible then
				return "You hear something " .. b .. ".", "darkGrey"
			end
		end
	}
	eventTypes.enemyAlert = {
		isCombat = true,
		investigateLocationOverride = "spottedEntityLocation",
		sourceEntityRelation = "self",
		audioRevealsSource = true,
		announceToPlayer = function(self, eventData, playerSource, sourceKnown, visible, audible)
			local a, b
			if eventData.alertType == "warcry" then
				a = "lets out a war cry"
				b = "let out a war cry"
			elseif eventData.alertType == "snarl" then
				a = "snarls aggressively"
				b = "snarl aggressively"
			elseif eventData.alertType == "chant" then
				a = "begins a sinister chant"
				b = "begin a sinister chant"
			elseif eventData.alertType == "hiss" then
				a = "hisses savagely"
				b = "hiss savagely"
			elseif eventData.alertType == "point" then
				a = "points at an enemy"
				b = "point at an enemy"
			else
				a = "alerts of an enemy"
				b = "alert of an enemy"
			end

			if playerSource then
				return "You " .. b .. ".", "darkCyan"
			elseif sourceKnown then
				return "The " .. self:getEntityDisplayName(eventData.sourceEntity) .. " " .. a .. ".", "darkRed"
			elseif visible then
				return "You see something " .. b .. ".", "darkRed"
			elseif audible then
				return "You hear something " .. b .. ".", "darkRed"
			end
		end
	}
	eventTypes.gunshot = {
		isAttack = true,
		isCombat = true,
		sourceEntityRelation = "objectUse",
		announceToPlayer = function(self, eventData, playerSource, sourceKnown, visible, audible)
			if playerSource then
				return "Your gun fires.", "lightGrey"
			elseif sourceKnown then
				return "The " .. self:getEntityDisplayName(eventData.sourceEntity) .. " fires a gun!", "red"
			elseif visible then
				return "You see a gunshot!", "red"
			elseif audible then
				return "You hear a gunshot!", "darkRed"
			end
		end
	}
	eventTypes.explosion = {
		isAttack = true,
		isCombat = true,
		sourceEntityRelation = "remoteCause",
		-- investigateLocationOverride = "explosionLocation" -- No need, the explosion event broadcast has x and y set to the explosion's location
		announceToPlayer = function(self, eventData, playerSource, sourceKnown, visible, audible)
			if visible then
				return "You see an explosion!", "yellow"
			elseif audible then
				return "You hear an explosion!", "darkYellow"
			end
		end
	}
	eventTypes.gibbing = {
		isDamageTaken = true,
		isCombat = true,
		sourceEntityRelation = "doneTo",
		announceToPlayer = function(self, eventData, playerSource, sourceKnown, visible, audible)
			local material = self.state.materials[eventData.gibMaterial]
			local shownMaterialName = audible and not visible and material.soundCategory and material.soundCategory.displayName or material.displayName -- Fall back to material display name if material has no sound category, even if the explosion was heard and not seen
			-- local explodesIntoText = "body bursts into a shower of " .. shownMaterialName -- Too long for some names
			local explodesText = "body bursts open"
			if playerSource then
				return "Your " .. explodesText .. ".", "red"
			elseif sourceKnown then
				return "The " .. self:getEntityDisplayName(eventData.sourceEntity) .. "'s " .. explodesText .. ".", "red"
			elseif visible then
				return "You see an explosion of " .. shownMaterialName .. ".", "red"
			elseif audible then
				return "You hear an explosion of " .. shownMaterialName .. ".", "darkRed"
			end
		end
	}
end

return game
