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
	local startBlocksProjectiles = self:tileBlocksProjectiles(startX, startY)
	local endBlocksProjectiles = self:tileBlocksProjectiles(endX, endY)
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
	local range = math.ceil(math.sqrt((map.width - 1) ^ 2 + (map.height - 1) ^ 2)) + 8
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

return game
