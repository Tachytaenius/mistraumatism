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
			alwaysShowConnections = true,
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
		archwayLeft = {
			displayName = "large archway",
			pretendConnectionTypeName = "wall",
			solidity = "passable",
			character = "/"
		},
		archwayRight = {
			displayName = "large archway",
			pretendConnectionTypeName = "wall",
			solidity = "passable",
			character = "\\"
		},
		arrowSlit = {
			displayName = "arrow slit",
			pretendConnectionTypeName = "wall",
			solidity = "projectilePassable", -- not "solid" so projectiles can move through, not "passable" so that entities can't
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
		brickWall = {
			displayName = "brick wall",
			solidity = "solid",
			character = "O",
			boxDrawingNumber = 2,
			pretendConnectionTypeName = "wall",
			blocksLight = true
		},
		livingWall = {
			displayName = "living wall",
			solidity = "solid",
			character = "▒",
			pretendConnectionTypeName = "wall",
			blocksLight = true
		},
		livingFloor = {
			displayName = "living floor",
			solidity = "passable",
			character = "░"
		},
		support = {
			displayName = "support",
			solidity = "passable",
			character = "I"
		},
		closedHatch = {
			displayName = "closed hatch",
			solidity = "passable",
			hatchState = "closed",
			stateChangeSoundRange = 5,
			character = "│",
			swapColours = true
		},
		openHatch = {
			displayName = "open hatch",
			solidity = "fall",
			hatchState = "open",
			character = "║",
			stateChangeSoundRange = 5,
			deleteSpatter = "all"
		},
		diningTable = {
			displayName = "dining table",
			solidity = "projectilePassable", -- not "solid" so projectiles can move through, not "passable" so that entities can't
			blocksLight = false,
			boxDrawingNumber = 2,
			swapColours = true,
			character = "╥",
			allowIncomingConnectionTypeNames = {ornateCarpet = true}
		},
		hugeBookshelf = {
			displayName = "huge bookshelf",
			solidity = "solid",
			blocksLight = true,
			lightSlipPast = true,
			swapColours = true,
			character = "≡",
			allowIncomingConnectionTypeNames = {ornateCarpet = true}
		},
		meshWall = {
			displayName = "mesh wall",
			solidity = "projectilePassable",
			blocksLight = false,
			swapColours = false,
			character = "#"
		},
		heavyPipes = {
			displayName = "heavy pipes",
			solidity = "solid",
			character = "÷",
			blocksLight = true,
			lightSlipPast = true,
			alwaysShowConnections = true,
			boxDrawingNumber = 2,
			allowIncomingConnectionTypeNames = {wall = true}
		},
		lightPipes = {
			displayName = "light pipes",
			solidity = "solid",
			character = "√",
			blocksLight = true,
			lightSlipPast = true,
			alwaysShowConnections = true,
			boxDrawingNumber = 1,
			pretendConnectionTypeName = "heavyPipes",
			allowIncomingConnectionTypeNames = {wall = true}
		},
		horizontalConveyorBelt = {
			displayName = "conveyor belt",
			solidity = "passable",
			character = "║",
			swapColours = true,
			liquidSpatterColourInvert = true
		},
		verticalConveyorBelt = {
			displayName = "conveyor belt",
			solidity = "passable",
			character = "═",
			swapColours = true,
			liquidSpatterColourInvert = true
		},
		controlPanel = {
			displayName = "machine panel",
			solidity = "solid",
			blocksLight = true,
			lightSlipPast = true,
			character = "%",
			secondaryColour = "cyan",
			swapColours = true,
			pretendConnectionTypeName = "machineCasing",
			allowIncomingConnectionTypeNames = {floorWiring = true}
		},
		machineCasing = {
			displayName = "machine casing",
			solidity = "solid",
			blocksLight = true,
			lightSlipPast = true,
			character = "┼",
			secondaryColour = "lightGrey",
			swapColours = true,
			boxDrawingNumber = 1,
			allowIncomingConnectionTypeNames = {floorWiring = true}
		},
		floorWiring = {
			displayName = "floor wiring",
			solidity = "passable",
			character = "≥",
			boxDrawingNumber = 2
		},
		wallWiring = {
			displayName = "wall wiring",
			solidity = "solid",
			character = "≡",
			boxDrawingNumber = 2,
			blocksLight = true,
			swapColours = true,
			pretendConnectionTypeName = "floorWiring",
			allowIncomingConnectionTypeNames = {wall = true}
		},
		conveyorIO = {
			displayName = "conveyor I/O",
			solidity = "solid",
			character = "▀",
			blocksLight = true,
			lightSlipPast = true,
			allowIncomingConnectionTypeNames = {machineCasing = true, crateWall = true}
		}
	}
end

return game
