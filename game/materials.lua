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
	addMaterial("bloodBlue", "blue blood", "darkBlue", "liquid")
	addMaterial("bloodGreen", "green blood", "darkGreen", "liquid")
	addMaterial("fleshRed", "flesh", "red", "solid")
	addMaterial("fleshYellow", "yellow flesh", "yellow", "solid")
	addMaterial("bone", "bone", "white", "solid")

	addMaterial("water", "water", "darkBlue", "liquid")

	addMaterial("steel", "steel", "darkGrey", "solid")
	addMaterial("iron", "iron", "darkGrey", "solid")
	addMaterial("gold", "gold", "yellow", "solid")
	addMaterial("stone", "stone", "lightGrey", "solid")
	addMaterial("stoneGreen", "green stone", "darkGreen", "solid")
	addMaterial("concrete", "concrete", "lightGrey", "solid")
	addMaterial("labTiles", "lab tiles", "white", "solid")

	addMaterial("porcelain", "porcelain", "white", "solid")
	addMaterial("plywood", "plywood", "darkYellow", "solid")
	addMaterial("lino", "lino", "darkGrey", "solid")

	addMaterial("crateBrown", "brown crate", "darkYellow", "solid")
	addMaterial("crateYellow", "yellow crate", "yellow", "solid")

	addMaterial("ornateCarpet", "gold and cloth", "red", "solid")
	addMaterial("grass", "grass", "green", "solid")
	addMaterial("soilLoamless", "loamless soil", "darkYellow", "solid")
	addMaterial("roseWithered", "withered rose", "darkYellow", "solid")

	addMaterial("wood", "wood", "darkYellow", "solid")
	addMaterial("paper", "paper", "white", "solid")
	addMaterial("plasticRed", "red plastic", "darkRed", "solid")
	addMaterial("plasticBlack", "black plastic", "darkGrey", "solid")
	addMaterial("brass", "brass", "yellow", "solid")
	addMaterial("aluminium", "aluminium", "lightGrey", "solid")
end

return game
