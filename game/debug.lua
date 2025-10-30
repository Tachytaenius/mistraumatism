local game = {}

-- The projectile testing functions are not to be maintained and may not work after things change elsewhere in the codebase
-- These functions are for testing purposes only. They are... not fast
function game:testProjectilePath(startX, startY, endX, endY, dummyEntity, range)
	local state = self.state
	local initialHealth = 100
	dummyEntity.x = endX
	dummyEntity.y = endY
	dummyEntity.health = initialHealth
	self:newProjectile({
		startX = startX,
		startY = startY,
		subtickMoveTimerLength = 1,
		damage = 1,
		range = range,

		aimX = endX,
		aimY = endY
	})
	while #state.projectiles > 0 do
		self:updateProjectiles()
	end
	local hit = dummyEntity.health ~= initialHealth
	local startBlocksProjectiles = self:tileBlocksAirMotion(startX, startY)
	local endBlocksProjectiles = self:tileBlocksAirMotion(endX, endY)
	local sameTile = startX == endX and startY == endY
	local hitscan = self:hitscan(startX, startY, endX, endY)
	local visibleButUnreachable = not sameTile and endBlocksProjectiles
	local shouldHit = hitscan and not visibleButUnreachable
	return hit == shouldHit, hit, shouldHit
end
function game:testProjectilePaths()
	local startTime = love.timer.getTime()
	local progressTimeInterval = 5
	local previousTime = startTime
	local dummyEntity = self:newCreatureEntity({
		creatureTypeName = "zombie"
	})
	local map = self.state.map
	local range = math.ceil(self:length(map.width - 1, map.height - 1)) + 8
	local failures = 0
	local total = 0
	local target = (map.width * map.height) ^ 2
	for startX = 0, map.width - 1 do
		for startY = 0, map.height - 1 do
			for endX = 0, map.width - 1 do
				for endY = 0, map.height - 1 do
					local success, hit, shouldHit = self:testProjectilePath(startX, startY, endX, endY, dummyEntity, range)

					if not success then
						failures = failures + 1
					end
					total = total + 1
					local currentTime = love.timer.getTime()

					if
						math.floor((previousTime - startTime) / progressTimeInterval) <
						math.floor((currentTime - startTime) / progressTimeInterval)
					then
						print(total .. "/" .. target .. " tests completed, " .. failures .. " failures, " .. math.floor(total / target * 100) .. "% done.")
					end
					previousTime = currentTime
				end
			end
		end
	end
	for i, entity in ipairs(self.state.entities) do
		if entity == dummyEntity then
			table.remove(self.state.entities, i)
			break
		end
	end
	local successes = total - failures
	local comment =
		total == 0 and "No tests run." or
		failures == 0 and "All successful!" or
		("Something is wrong... " .. failures .. " failures.")
	print(successes .. "/" .. total .. " tests passed. " .. comment)
end

-- Call this in debugOnNewState
function game:enableArmourTesting()
	-- For testing armour (also set --noPlayer and an appropriate start level like --startLevel=debug (also send --skipIntro))
	self.state.testingArmour = true
	self.state.fastActions = true
	self.state.meleeOnly = true
	self.fastForward = true
	self.noDraw = true
end
-- The test will take place on the top left tile of the map.
local victims = {
	{
		creatureTypeName = "human"
	},
	{
		creatureTypeName = "human",
		newArmourParams = {
			itemTypeName = "knightlyArmour",
			material = "steel"
		}
	},
	{
		creatureTypeName = "human",
		newArmourParams = {
			itemTypeName = "tacticalArmour",
			material = "superPolymer"
		}
	},
	{
		creatureTypeName = "human",
		newArmourParams = {
			itemTypeName = "tacticalArmour",
			material = "hyperPolymer"
		}
	}
}
local assailants = {
	{
		creatureTypeName = "zombie"
	},
	{
		creatureTypeName = "skeleton",
		newHeldItemParams = {
			itemTypeName = "scythe",
			material = "iron"
		}
	},
	{
		creatureTypeName = "imp"
	},
	{
		creatureTypeName = "hellNoble"
	}
}
local majorKey, minorKey =
	"nextArmourTestAssailantIndex",
	"nextArmourTestVictimIndex"
local majorTable, minorTable =
	assailants,
	victims
local swap = true
if swap then
	majorTable, minorTable = minorTable, majorTable
	majorKey, minorKey = minorKey, majorKey
end
function game:testArmourOnTick()
	local state = self.state

	state.armourTestPairingData = state.armourTestPairingData or {}
	state.nextArmourTestVictimIndex = state.nextArmourTestVictimIndex or 1
	state.nextArmourTestAssailantIndex = state.nextArmourTestAssailantIndex or 1

	local function record()
		if not state.armourTestVictim then
			return
		end
		local data = state.armourTestPairingData[#state.armourTestPairingData]
		local lastDataEntry = data[#data]
		local victim = state.armourTestVictim
		local armourInfo = victim.currentWornItem and self:getTotalArmourInfo(victim.currentWornItem)
		data[#data+1] = {
			dead = victim.dead,
			health = victim.health,
			damage = lastDataEntry and lastDataEntry.health - victim.health,
			blood = victim.blood,
			bloodLoss = lastDataEntry and lastDataEntry.blood - victim.blood,
			defence = armourInfo and armourInfo.defence,
			durability = armourInfo and armourInfo.durability,
			damageMultiplier = armourInfo and self:getDefenceMultiplier(armourInfo.defence),
			wear = victim.currentWornItem and (victim.currentWornItem.armourWear or 0) or nil
		}
	end

	local x, y = 0, 0
	if not state.armourTestVictim or state.armourTestVictim.dead then
		-- Record and reset, next test
		record()
		state.armourTestVictim = nil
		if state.armourTestAssailant then
			state.armourTestAssailant.actions = {}
			state.armourTestAssailant.noAI = true
			state.armourTestAssailant.health = 0
			state.armourTestAssailant = nil
		end

		if state.lastArmourTestPair then
			state.testingArmour = false
			self:printArmourTestData(state.armourTestPairingData)
			return
		end
	end
	if not state.armourTestVictim and not state.lastArmourTestPair then
		assert(not state.armourTestAssailant, "Assailant but no victim? They should be created/destroyed at the same time.")
		local nextVictim = victims[state.nextArmourTestVictimIndex]
		local nextAssailant = assailants[state.nextArmourTestAssailantIndex]

		table.insert(state.armourTestPairingData, {victim = nextVictim, assailant = nextAssailant})

		state.armourTestVictim = self:newCreatureEntity({
			creatureTypeName = nextVictim.creatureTypeName,
			team = "person",
			x = x, y = y,
			noAI = true,
			currentWornItem = nextVictim.newArmourParams and self:newItemData(nextVictim.newArmourParams) or nil
		})

		state.armourTestAssailant = self:newCreatureEntity({
			creatureTypeName = nextAssailant.creatureTypeName,
			team = "monster",
			x = x, y = y
		})
		if nextAssailant.newHeldItemParams then
			if state.armourTestAssailant.creatureType.inventorySize >= 1 then
				state.armourTestAssailant.inventory[1].item = self:newItemData(nextAssailant.newHeldItemParams)
				state.armourTestAssailant.inventory.selectedSlot = 1
			end
		end

		state[majorKey] = state[majorKey] + 1
		if state[majorKey] > #majorTable then
			state[majorKey] = 1
			state[minorKey] = state[minorKey] + 1
			if state[minorKey] > #minorTable then
				state[minorKey] = 1

				state.lastArmourTestPair = true

				record()
				return
			end
		end
	end

	record()
end

function game:debugOnTick()
	if self.state.testingArmour then
		self:testArmourOnTick()
	end
end

function game:printArmourTestData(data)
	local outLines = {}
	for i, pairing in ipairs(data) do
		local lineTable = {}

		lineTable[#lineTable+1] = "@" .. (#pairing - 1) .. " hits:"

		lineTable[#lineTable+1] = pairing.victim.creatureTypeName
		if pairing.victim.newArmourParams then
			lineTable[#lineTable+1] = "(" .. pairing.victim.newArmourParams.itemTypeName
			lineTable[#lineTable+1] = pairing.victim.newArmourParams.material .. ")"
		else
			lineTable[#lineTable+1] = "(unarmoured)"
		end

		lineTable[#lineTable+1] = pairing.assailant.creatureTypeName
		if pairing.assailant.newHeldItemParams then
			lineTable[#lineTable+1] = "(" .. pairing.assailant.newHeldItemParams.itemTypeName
			lineTable[#lineTable+1] = pairing.assailant.newHeldItemParams.material .. ")"
		else
			lineTable[#lineTable+1] = "(unarmed)"
		end

		local showSteps = true
		if showSteps then
			for i, record in ipairs(pairing) do
				outLines[#outLines+1] = table.concat(lineTable, " ")
				lineTable = {}

				lineTable[#lineTable+1] = "\t#" .. i
				if record.dead then
					lineTable[#lineTable+1] = "DEAD"
				end
				lineTable[#lineTable+1] = record.health .. "H"
				lineTable[#lineTable+1] = (record.damage or "-") .. "D"
				lineTable[#lineTable+1] = record.blood .. "B"
				lineTable[#lineTable+1] = (record.bloodLoss or "-") .. "L"
				lineTable[#lineTable+1] = (record.defence or "-") .. "E"
				lineTable[#lineTable+1] = (record.wear and (record.wear .. "/" .. record.durability) or "-") .. "U"
				lineTable[#lineTable+1] = (record.damageMultiplier and math.floor(record.damageMultiplier * 100 + 0.5) or "-") .. "%"
			end
		end

		outLines[#outLines+1] = table.concat(lineTable, " ")

		local endOfSet = (i - 1) % #majorTable == #majorTable - 1
		if endOfSet and i ~= #data then -- Spacing between assailant sets
			outLines[#outLines+1] = ""
		end
	end
	local dataText = table.concat(outLines, "\n")
	print(dataText)
	love.event.quit()
end

return game
