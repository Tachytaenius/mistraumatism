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
			character = "∙",
			ignoreSpatter = true,
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
			character = "#"
		},
	}
end

return game
