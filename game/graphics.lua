local util = require("util")

local game = {}

function game:clearFramebuffer()
	local framebuffer = self.currentFramebuffer
	for x = 0, self.framebufferWidth - 1 do
		local column = framebuffer[x]
		for y = 0, self.framebufferHeight - 1 do
			local cell = column[y]
			cell.character = " "
			cell.foregroundColour = "white"
			cell.backgroundColour = "black"
		end
	end
end

function game:draw() -- After this function completes, the result is in currentFramebuffer
	self.currentFramebuffer, self.otherFramebuffer = self.otherFramebuffer, self.currentFramebuffer
	local framebuffer = self.currentFramebuffer
	local state = self.state
	self:clearFramebuffer()

	local viewportScreenX, viewportScreenY = 0, 0
	local topLeftX = math.floor(state.player.x - self.viewportWidth / 2)
	local topLeftY = math.floor(state.player.y - self.viewportHeight / 2)
	local function drawCharacter(worldX, worldY, character, foregroundColour, backgroundColour)
		local viewportX = worldX - topLeftX
		local viewportY = worldY - topLeftY
		if
			0 <= viewportX and viewportX < self.viewportWidth and
			0 <= viewportY and viewportY < self.viewportHeight
		then
			local cell = framebuffer[viewportX + viewportScreenX][viewportY + viewportScreenY]
			cell.character = character
			cell.foregroundColour = foregroundColour
			cell.backgroundColour = backgroundColour
		end
	end

	local visibilityMap = self:computeVisibilityMap(state.player.x, state.player.y, 24) -- For the next draw(s)

	for viewportSpaceX = 0, self.viewportWidth - 1 do
		local visibilityColumn = visibilityMap[viewportSpaceX]
		local x = viewportSpaceX + viewportScreenX
		local column = framebuffer[x]
		for viewportSpaceY = 0, self.viewportHeight - 1 do
			if not visibilityColumn[viewportSpaceY] then
				goto continue
			end
			local y = viewportSpaceY + viewportScreenY
			local cell = column[y]

			local tileX, tileY = x + topLeftX, y + topLeftY
			local tile = self:getTile(tileX, tileY)

			if not tile then
				cell.character = " "
				cell.foregroundColour = "white"
				cell.backgroundColour = "black"
				goto continue
			end

			cell.backgroundColour = "black"

			if tile.type == "floor" then
				cell.character = "+"
				cell.foregroundColour = "lightGrey"
			elseif tile.type == "wall" then
				local right = self:getTile(tileX + 1, tileY)
				local up    = self:getTile(tileX, tileY - 1)
				local left  = self:getTile(tileX - 1, tileY)
				local down  = self:getTile(tileX, tileY + 1)
				local num = 2
				local boxCharacter = util.getBoxDrawingCharacter(
					right and right.type == "wall" and num or 0,
					up    and up.type == "wall"    and num or 0,
					left  and left.type == "wall"  and num or 0,
					down  and down.type == "wall"  and num or 0
				)
				cell.character = boxCharacter or "O"
				cell.foregroundColour = "lightGrey"
			elseif tile.type == "pit" then
				cell.character = "·"
				cell.foregroundColour = "darkGrey"
			end

			::continue::
		end
	end

	for _, entity in ipairs(state.entities) do
		drawCharacter(entity.x, entity.y, "@", "white", "black")
	end
end

function game:newFramebuffer()
	local framebuffer = {}
	for x = 0, self.framebufferWidth - 1 do
		local column = {}
		framebuffer[x] = column
		for y = 0, self.framebufferHeight - 1 do
			local cell = {
				character = " ",
				foregroundColour = "white",
				backgroundColour = "black"
			}
			column[y] = cell
		end
	end
	return framebuffer
end

return game
