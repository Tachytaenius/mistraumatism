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
		shortGrass = {
			displayName = "short grass",
			solidity = "passable",
			character = "▒"
		},
		grass = {
			displayName = "grass",
			solidity = "passable",
			secondaryColour = "darkGreen", -- Make a system to take the colour from the material (and invert its brightness) if non-green grasses are needed
			character = "▒"
		},
		longGrass = {
			displayName = "long grass",
			solidity = "passable",
			secondaryColour = "darkGreen", -- Make a system to take the colour from the material (and invert its brightness) if non-green grasses are needed
			character = "▓"
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
		wornWall = { -- Eroded
			displayName = "worn wall",
			solidity = "solid",
			character = "░",
			swapColours = true,
			pretendConnectionTypeName = "wall",
			allowIncomingConnectionTypeNames = {wall = true},
			blocksLight = true
		},
		roughWall = {  -- Natural
			displayName = "rough wall",
			solidity = "solid",
			character = "▓",
			pretendConnectionTypeName = "wall",
			blocksLight = true
		},
		wornFloor = {
			displayName = "worn floor",
			solidity = "passable",
			character = "▓",
			swapColours = true
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
		},
		ornateFloor = {
			displayName = "ornate floor",
			solidity = "passable",
			character = "♦",
			swapColours = true,
			secondaryColour = "darkCyan"
		},
		floorPortal1 = {
			displayName = "floor portal",
			solidity = "fall",
			secondaryColour = "darkCyan",
			animationTiles = {"▓", "▒", "░", "▒"},
			animationTime = 8
		},
		floorPortal2 = {
			displayName = "floor portal",
			solidity = "fall",
			secondaryColour = "darkCyan",
			animationTiles = {"▒", "░", "▒", "▓"},
			animationTime = 8
		},
		floorPortal3 = {
			displayName = "floor portal",
			solidity = "fall",
			secondaryColour = "darkCyan",
			animationTiles = {"░", "▒", "▓", "▒"},
			animationTime = 8
		},
		sand = {
			displayName = "sand",
			solidity = "passable",
			secondaryColour = "yellow",
			darkenColour = true,
			character = "▒"
		}
	}
end

return game
