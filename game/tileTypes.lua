local game = {}

function game:loadTileTypes()
	local state = self.state
	state.tileTypes = {
		wall = {
			displayName = "wall",
			solidity = "solid",
			character = "O",
			boxDrawingNumber = 2,
			blocksLight = true
		},
		floor = {
			displayName = "floor",
			solidity = "passable",
			character = "+"
		},
		pit = {
			displayName = "pit",
			solidity = "fall",
			character = "·",
			deleteSpatter = "all",
			darkenColour = true
		},
		crateWall = {
			displayName = "crate",
			solidity = "solid",
			character = "╬",
			blocksLight = true,
			lightSlipPast = true,
			boxDrawingNumber = 2,
			swapColours = true,
			swapColoursSingleOnly = true
		},
		drain = {
			displayName = "drain",
			solidity = "passable",
			deleteSpatter = "liquid",
			character = "#"
		},
		turf = {
			displayName = "turf",
			solidity = "passable",
			-- secondaryColour = "darkGreen",
			character = "▒"
		},
		flowerbed = {
			displayName = "flowerbed",
			solidity = "passable",
			character = "░"
		},
		ornateCarpet = {
			displayName = "ornate carpet",
			solidity = "passable",
			character = " ", -- ░
			boxDrawingNumber = 1,
			no4WayJunction = true,
			blocksLight = false,
			swapColours = true,
			secondaryColour = "yellow"
		},
		archway = {
			displayName = "archway",
			pretendConnectionTypeName = "wall", -- Join to walls
			solidity = "passable",
			character = "∩"
		},
		arrowSlit = {
			displayName = "arrow slit",
			pretendConnectionTypeName = "wall",
			solidity = "gap", -- not "solid" so projectiles can move through, not "passable" so that entities can't
			blocksLight = false,
			swapColours = true,
			character = "↕"
		},
		glassWindow = {
			displayName = "glass window",
			pretendConnectionTypeName = "wall",
			solidity = "solid",
			blocksLight = false,
			swapColours = true,
			character = "■",
			secondaryColour = "cyan"
		},
		drawbridgeVertical = {
			displayName = "drawbridge",
			solidity = "passable",
			character = "═",
			swapColours = true
		},
		roughWall = {
			displayName = "rough wall",
			solidity = "solid",
			character = "▓",
			pretendConnectionTypeName = "wall",
			blocksLight = true
		},
		roughFloor = {
			displayName = "rough floor",
			solidity = "passable",
			character = "░"
		},
	}
end

return game
