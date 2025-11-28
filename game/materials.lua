local game = {}

function game:loadMaterials()
	local state = self.state

	state.materials = {}
	local function addMaterial(name, displayName, colour, matterState)
		local newMaterial = {
			displayName = displayName,
			colour = colour,
			matterState = matterState
		}
		state.materials[name] = newMaterial
		return newMaterial
	end

	state.materialSoundCategories = {}
	local function addMaterialSoundCategory(name, displayName)
		local newMaterialSoundCategory = {
			displayName = displayName
		}
		state.materialSoundCategories[name] = newMaterialSoundCategory
		return newMaterialSoundCategory
	end

	local function applySoundCategory(soundCategory, ...)
		for i = 1, select("#", ...) do
			select(i, ...).soundCategory = soundCategory
		end
	end

	applySoundCategory(addMaterialSoundCategory("blood", "blood"),
		addMaterial("bloodRed", "blood", "darkRed", "liquid"),
		addMaterial("bloodBlue", "blue blood", "darkBlue", "liquid"),
		addMaterial("bloodGreen", "green blood", "darkGreen", "liquid")
	)
	applySoundCategory(addMaterialSoundCategory("flesh", "flesh"),
		addMaterial("fleshRed", "flesh", "red", "solid"),
		addMaterial("fleshYellow", "yellow flesh", "yellow", "solid")
	)
	applySoundCategory(addMaterialSoundCategory("bone", "bone"),
		addMaterial("bone", "bone", "white", "solid")
	)

	addMaterial("water", "water", "darkBlue", "liquid")
	addMaterial("ice", "ice", "cyan", "solid")

	local steel = addMaterial("steel", "steel", "darkGrey", "solid")
	steel.armourInfo = {
		defence = 2,
		durability = 6
	}
	local iron = addMaterial("iron", "iron", "darkGrey", "solid")
	iron.armourInfo = {
		defence = 2,
		durability = 4
	}
	applySoundCategory(addMaterialSoundCategory("metal", "metal"),
		steel,
		iron,
		addMaterial("gold", "gold", "yellow", "solid"),
		addMaterial("copper", "copper", "darkYellow", "solid"),
		addMaterial("brass", "brass", "yellow", "solid"),
		addMaterial("aluminium", "aluminium", "lightGrey", "solid")
	)

	addMaterial("concrete", "concrete", "lightGrey", "solid")
	addMaterial("labTiles", "lab tiles", "white", "solid")
	addMaterial("plaster", "plaster", "white", "solid")
	addMaterial("leather", "leather", "darkYellow", "solid")

	addMaterial("polymer", "polymer", "darkGrey", "solid")
	local superPolymer = addMaterial("superPolymer", "super polymer", "darkCyan", "solid")
	superPolymer.armourInfo = {
		defence = 4,
		durability = 8
	}
	local hyperPolymer = addMaterial("hyperPolymer", "hyper polymer", "darkMagenta", "solid")
	hyperPolymer.armourInfo = {
		defence = 6,
		durability = 14
	}

	applySoundCategory(addMaterialSoundCategory("stone", "stone"),
		addMaterial("slate", "slate", "darkGrey", "solid"),
		addMaterial("granite", "granite", "lightGrey", "solid"),
		addMaterial("marble", "marble", "white", "solid"),
		addMaterial("marbleGreen", "green marble", "darkGreen", "solid"),
		addMaterial("obsidian", "obsidian", "darkGrey", "solid")
	)

	addMaterial("porcelain", "porcelain", "white", "solid")
	addMaterial("plywood", "plywood", "darkYellow", "solid")
	addMaterial("lino", "lino", "darkGrey", "solid")

	addMaterial("crateBrown", "brown crate", "darkYellow", "solid")
	addMaterial("crateYellow", "yellow crate", "yellow", "solid")

	addMaterial("ornateCarpet", "gold and cloth", "red", "solid")
	addMaterial("soilLoamless", "loamless soil", "darkYellow", "solid")

	applySoundCategory(addMaterial("grass", "grass"),
		addMaterial("zoysia", "zoysia", "green", "solid"),
		addMaterial("fescue", "fescue", "green", "solid")
	)

	addMaterial("ivy", "ivy", "darkGreen", "solid")
	local borage = addMaterial("borage", "borage", "blue", "solid")
	borage.flowerTile = "*"
	local roseWithered = addMaterial("rose", "rose", "red", "solid")
	roseWithered.flowerTile = "@"
	local roseWithered = addMaterial("roseWithered", "withered rose", "darkYellow", "solid")
	roseWithered.flowerTile = "§"

	applySoundCategory(addMaterialSoundCategory("wood", "wood"),
		addMaterial("mahogany", "mahogany", "darkYellow", "solid"),
		addMaterial("ginkgo", "ginkgo", "darkYellow", "solid"),
		addMaterial("palm", "palm", "darkYellow", "solid"),
		addMaterial("elder", "elder", "darkYellow", "solid")
	)

	addMaterial("paper", "paper", "white", "solid")
	addMaterial("cloth", "cloth", "white", "solid")

	applySoundCategory(addMaterialSoundCategory("plastic", "plastic"),
		addMaterial("plasticRed", "red plastic", "darkRed", "solid"),
		addMaterial("plasticGreen", "green plastic", "darkGreen", "solid"),
		addMaterial("plasticBlack", "black plastic", "darkGrey", "solid"),
		addMaterial("plasticBrown", "brown plastic", "darkYellow", "solid")
	)

	addMaterial("inflictionMagic", "grief and pain", "magenta", "liquid")
end

return game
