local game = {}

function game:loadMaterials()
	local state = self.state

	state.materials = {}
	local function addMaterial(name, displayName, colour, matterState)
		state.materials[name] = {
			displayName = displayName,
			colour = colour,
			matterState = matterState
		}
	end

	addMaterial("bloodRed", "blood", "darkRed", "liquid")
	addMaterial("bone", "bone", "white", "solid")

	addMaterial("steel", "steel", "darkGrey", "solid")
	addMaterial("stone", "stone", "lightGrey", "solid")
	addMaterial("labTiles", "lab tiles", "white", "solid")

	addMaterial("crateBrown", "brown crate", "darkYellow", "solid")
	addMaterial("crateYellow", "yellow crate", "yellow", "solid")
end

return game
