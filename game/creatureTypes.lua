local consts = require("consts")

local game = {}

function game:loadCreatureTypes()
	local state = self.state
	local creatureTypes = {}
	state.creatureTypes = creatureTypes

	creatureTypes.human = {
		displayName = "human",
		tile = "@",
		colour = "white",
		bloodMaterialName = "bloodRed",

		moveTimerLength = 6,
		swimMoveTimerLength = 18,
		breathingTimerLength = 900, -- 900 ticks / (18 ticks / step) = 50 steps when underwater. 0.03125 seconds / tick * 900 ticks = 28.125 seconds before drowning.
		sightDistance = 17,
		maxHealth = 16,
		maxBlood = 16,
		bleedHealRate = 16,
		meleeTimerLength = 5,
		meleeDamage = 3,
		meleeBleedRateAdd = 4,

		canOpenDoors = true,
		inventorySize = 9
	}

	creatureTypes.zombie = {
		displayName = "zombie",
		tile = "z",
		colour = "lightGrey",
		bloodMaterialName = "bloodRed",

		moveTimerLength = 12,
		sightDistance = 10,
		maxHealth = 10,
		maxBlood = 12,
		meleeTimerLength = 8,
		meleeDamage = 2,
		meleeBleedRateAdd = 3,
		shootAggressiveness = 0.5,

		inventorySize = 2
	}

	creatureTypes.skeleton = {
		displayName = "skeleton",
		tile = "s",
		colour = "white",
		fleshMaterialName = "bone",

		moveTimerLength = 5,
		sightDistance = 12,
		maxHealth = 5,
		meleeTimerLength = 4,
		meleeDamage = 2,
		meleeBleedRateAdd = 3,
		shootAggressiveness = 0.5,

		inventorySize = 2,
		spawnItemType = "scythe",
		spawnItemMaterial = "iron"
	}

	creatureTypes.slug = {
		displayName = "slug",
		tile = "~",
		colour = "darkGreen",
		fleshMaterialName = "fleshYellow",
		bloodMaterialName = "bloodBlue",

		moveTimerLength = 16,
		sightDistance = 6,
		maxHealth = 20,
		maxBlood = 10,
		bleedHealRate = 64,
		meleeTimerLength = 1,
		meleeDamage = 1,
		meleeBleedRateAdd = 5,
		shootAggressiveness = 0.85,

		projectileAbilities = {
			{
				name = "acidSingle",
				shootTime = 10,
				projectileTile = "•",
				projectileColour = "green",
				projectileSubtickMoveTimerLength = 256,
				damage = 6,
				bleedRateAdd = 15,
				range = 5
			},
			{
				name = "acidSpread",
				shootTime = 6,
				shotCount = 3,
				spread = consts.tau / 8,
				projectileTile = "•",
				projectileColour = "darkGreen",
				projectileSubtickMoveTimerLength = 768,
				damage = 2,
				bleedRateAdd = 5,
				range = 5
			}
		}
	}

	creatureTypes.imp = {
		displayName = "imp",
		tile = "I",
		colour = "darkYellow",
		bloodMaterialName = "bloodRed",

		moveTimerLength = 4,
		sightDistance = 15,
		maxHealth = 24,
		maxBlood = 24,
		bleedHealRate = 32,
		meleeTimerLength = 4,
		meleeDamage = 4,
		meleeBleedRateAdd = 16,
		meleeInstantBloodLoss = 1,
		shootAggressiveness = 0.25,

		canOpenDoors = true,

		projectileAbilities = {
			{
				name = "fireball",
				shootTime = 6,
				projectileTile = "☼",
				projectileColour = "yellow",
				projectileSubtickMoveTimerLength = 128,
				damage = 4,
				bleedRateAdd = 4,
				range = 12
			}
		}
	}

	creatureTypes.hellNoble = {
		displayName = "Hell noble",
		tile = "N",
		colour = "darkRed",
		bloodMaterialName = "bloodGreen",

		moveTimerLength = 5,
		sightDistance = 12,
		maxHealth = 100,
		maxBlood = 100,
		bleedHealRate = 32,
		meleeTimerLength = 5,
		meleeDamage = 15,
		meleeBleedRateAdd = 64,
		meleeInstantBloodLoss = 5,
		shootAggressiveness = 0.2,

		canOpenDoors = true,

		projectileAbilities = {
			{
				name = "fireball",
				shootTime = 12,
				projectileTile = "☼",
				projectileColour = "green",
				projectileSubtickMoveTimerLength = 64,
				damage = 10,
				bleedRateAdd = 40,
				range = 20
			}
		}
	}

	creatureTypes.hellKing = {
		displayName = "Hell king",
		tile = "K",
		colour = "red",
		flashDarkerColour = true,
		bloodMaterialName = "bloodGreen",

		moveTimerLength = 2,
		sightDistance = 20,
		maxHealth = 400,
		maxBlood = 400,
		bleedHealRate = 128,
		meleeTimerLength = 1,
		meleeDamage = 40,
		meleeBleedRateAdd = 256,
		meleeInstantBloodLoss = 20,
		shootAggressiveness = 0.25,

		canOpenDoors = true,

		projectileAbilities = {
			{
				name = "boulder",
				shootTime = 8,
				projectileTile = "•",
				projectileColour = "lightGrey",
				projectileSubtickMoveTimerLength = 48,
				projectileSubtickMoveTimerLengthChange = 32,
				projectileSubtickMoveTimerLengthMax = 256,
				damage = 30,
				bleedRateAdd = 200,
				instantBloodLoss = 18,
				range = 14
			},
			{
				name = "fireball",
				shootTime = 6,
				projectileTile = "☼",
				projectileColour = "green",
				projectileSubtickMoveTimerLength = 32,
				damage = 20,
				bleedRateAdd = 100,
				instantBloodLoss = 9,
				range = 20
			}
		}
	}

	creatureTypes.angler = {
		displayName = "angler",
		tile = "Ä",
		colour = "darkYellow",
		bloodMaterialName = "bloodRed",

		aquatic = true,
		cantMoveOnLand = true,
		moveTimerLength = nil,
		swimMoveTimerLength = 15,
		breathingTimerLength = 300,
		sightDistance = 24,
		maxHealth = 50,
		maxBlood = 50,
		bleedHealRate = 12,
		meleeTimerLength = 4,
		meleeDamage = 24,
		meleeBleedRateAdd = 80,
		meleeInstantBloodLoss = 10,
	}
	creatureTypes.smallFish1 = {
		displayName = "small fish",
		tile = ",",
		colour = "darkGreen",
		bloodMaterialName = "bloodRed",

		aquatic = true,
		cantMoveOnLand = true,
		moveTimerLength = nil,
		swimMoveTimerLength = 2,
		breathingTimerLength = 100,
		sightDistance = 9,
		maxHealth = 1,
		maxBlood = 1,
		bleedHealRate = 12
	}
	creatureTypes.smallFish2 = {
		displayName = "small fish",
		tile = "α",
		colour = "darkCyan",
		bloodMaterialName = "bloodRed",

		aquatic = true,
		cantMoveOnLand = true,
		moveTimerLength = nil,
		swimMoveTimerLength = 4,
		breathingTimerLength = 120,
		sightDistance = 9,
		maxHealth = 2,
		maxBlood = 2,
		bleedHealRate = 12
	}
end

return game
