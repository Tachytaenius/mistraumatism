local commands = require("commands")
local util = require("util")

local game = {}

function game:initLevelSelectTendrils()
	-- local seed = love.math.random(0, 2^32-1)
	-- print(seed)
	local seed = 3683702864
	local generator = love.math.newRandomGenerator(seed)

	local width, height = self.framebufferWidth, self.framebufferHeight
	local map = {}
	for x = 0, width - 1 do
		map[x] = {}
		for y = 0, height - 1 do
			map[x][y] = {walkedBy = nil, edges = {0, 0, 0, 0}}
		end
	end
	map.width, map.height = width, height

	local heads = {
		{x = 21, y = 9, dir = "left"},
		{x = 33, y = 9, dir = "right"}
	}
	for i, head in ipairs(heads) do
		head.id = i
		head.size = 2
		head.steps = 0
	end

	local directions = {"right", "up", "left", "down"}
	for i, direction in ipairs(directions) do
		directions[direction] = i
	end

	local opposites = {right = "left", up = "down", left = "right", down = "up"}

	local steps = 50
	local dirChangeChance = 0.7
	local branchChance = 0.12
	for _=1, steps do
		util.shuffle(heads)
		local headI = 1
		while headI <= #heads do
			local head = heads[headI]
			if head.inited and generator:random() < dirChangeChance then
				head.dir = directions[generator:random(#directions)]
			end
			head.inited = true
			local px, py = head.x, head.y
			local kill = false
			if px < 0 or px >= width or py < 0 or py >= height then
				kill = true
			end
			local ox, oy = self:getDirectionOffset(head.dir)
			head.x = head.x + ox
			head.y = head.y + oy
			local pstep = head.steps
			head.steps = head.steps + 1
			head.size = generator:random() < (head.steps - 10) / 10 and 1 or 2
			local bounce = false
			if head.x < 0 or head.x >= width or head.y < 0 or head.y >= height then
				-- kill = true
				bounce = true
			elseif map[head.x][head.y].walkedBy --[=[and map[head.x][head.y].walkedBy ~= head.id]=] then
				-- kill = true
				bounce = true
			end
			if bounce then
				head.dir = opposites[head.dir]
				head.x = px
				head.y = py
				head.steps = pstep
			end
			if not kill then
				if not bounce then
					map[head.x][head.y].edges[directions[opposites[head.dir]]] = head.size
					map[head.x][head.y].walkedBy = head.id
					map[head.x][head.y].step = head.steps

					map[px][py].edges[directions[head.dir]] = head.size
					map[px][py].walkedBy = head.id
					map[px][py].step = pstep
				end
				local branch = generator:random() < branchChance
				if branch then
					-- side is 1 or -1
					local side = (generator:random(2) - 1) * 2 - 1
					local bDir = directions[(directions[head.dir] + side - 1) % #directions + 1]
					table.insert(heads, {
						x = head.x,
						y = head.y,
						dir = bDir,
						id = #heads,
						steps = head.steps,
						size = head.size
					})
				end
			end
			if kill then
				table.remove(heads, headI)
			else
				headI = headI + 1
			end
		end
	end

	return map, steps
end

function game:updateLevelSelect(dt)
	local info = self.levelSelectInfo
	local levels = info.levels
	local selector = info.selector

	local move = 0
	if
		commands.checkCommand("scrollListBackwards")
		-- commands.checkCommand("moveLeft") or
		-- commands.checkCommand("moveUp")
	then
		move = move - 1
	end
	if
		commands.checkCommand("scrollListForwards")
		-- commands.checkCommand("moveRight") or
		-- commands.checkCommand("moveDown")
	then
		move = move + 1
	end
	info.selector = (selector - 1 + move) % #levels + 1

	if commands.checkCommand("shoot") then
		info.flickerIntroEnabled = not info.flickerIntroEnabled
	end

	if commands.checkCommand("confirm") then
		return info.selectFunction()
	end

	info.changeTendrilsTimer = info.changeTendrilsTimer + dt
	local steps = math.floor(info.changeTendrilsTimer / info.tendrilStepTime)
	info.changeTendrilsTimer = info.changeTendrilsTimer % info.tendrilStepTime
	info.currentTendrilStep = (info.currentTendrilStep + steps) % (info.tendrilSteps + info.tendrilStepExtra)
	info.time = info.time + dt
end

return game
