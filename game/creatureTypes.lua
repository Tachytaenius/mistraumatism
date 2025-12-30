local consts = require("consts")

local game = {}

function game:loadCreatureTypes()
	local state = self.state
	local creatureTypes = {}
	state.creatureTypes = creatureTypes

	-- NOTE: Like with gun behaviour variables in item types, the creature type AI control variables were designed to reach specific intended behaviours, and random combinations of the variables may not lead to good results. With certain combinations you may find monsters that act in nonsensical ways like running up to you and doing nothing.

	creatureTypes.human = {
		displayName = "human",
		tile = "@",
		colour = "white",
		bloodMaterialName = "bloodRed",
		size = 64,

		moveTimerLength = 6,
		dodgeTimerLength = 3,
		dodgeSteadyTimerLength = 5,
		jumpTimerLength = 4,
		jumpAirborneTimerLength = 2,
		jumpSteadyTimerLength = 13,
		swimMoveTimerLength = 18,
		breathingTimerLength = 900, -- 900 ticks / (18 ticks / step) = 50 steps when submerged. 0.03125 seconds / tick * 900 ticks = 28.125 seconds before drowning.
		sightDistance = 17,
		maxHealth = 16,
		maxBlood = 16,
		bleedHealRate = 24,
		meleeTimerLength = 5,
		meleeDamage = 3,
		meleeBleedRateAdd = 4,

		hears = true,
		alertAction = "warcry",
		alertActionUsesVocalisation = true,
		vocalisationRange = 14,
		painDamageThreshold = 3,

		canOpenDoors = true,
		inventorySize = 9,

		psychicDamageDeathPoint = 120
	}

	creatureTypes.zombie = {
		displayName = "zombie",
		tile = "z",
		colour = "lightGrey",
		bloodMaterialName = "bloodRed",
		size = 48,

		moveTimerLength = 10,
		sightDistance = 16,
		maxHealth = 10,
		maxBlood = 12,
		meleeTimerLength = 8,
		meleeDamage = 2,
		meleeBleedRateAdd = 3,
		shootAggressiveness = 0.5,

		hears = true,
		alertAction = "snarl",
		alertActionUsesVocalisation = true,
		vocalisationRange = 8,
		painDamageThreshold = 2,

		canOpenDoors = true,
		inventorySize = 2,

		psychicDamageDeathPoint = 24
	}

	creatureTypes.skeleton = {
		displayName = "skeleton",
		tile = "s",
		colour = "white",
		fleshMaterialName = "bone",
		size = 32,

		moveTimerLength = 5,
		sightDistance = 12,
		maxHealth = 5,
		meleeTimerLength = 6,
		meleeDamage = 2,
		meleeBleedRateAdd = 3,
		shootAggressiveness = 0.5,

		alertAction = "point",
		painDamageThreshold = 1,
		gibText = "body shatters",

		canOpenDoors = true,
		inventorySize = 2,

		psychicDamageDeathPoint = 16
	}

	creatureTypes.slug = {
		displayName = "slug",
		tile = "~",
		colour = "darkGreen",
		fleshMaterialName = "fleshYellow",
		bloodMaterialName = "bloodBlue",
		size = 32,

		moveTimerLength = 16,
		sightDistance = 6,
		maxHealth = 20,
		maxBlood = 10,
		bleedHealRate = 64,
		meleeTimerLength = 1,
		meleeDamage = 1,
		meleeBleedRateAdd = 5,
		shootAggressiveness = 0.85,

		attackDeadTargets = true,

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

	creatureTypes.snail = {
		displayName = "snail",
		tile = "ª",
		colour = "darkYellow",
		fleshMaterialName = "fleshYellow",
		bloodMaterialName = "bloodBlue",
		size = 48,

		moveTimerLength = 16,
		sightDistance = 7,
		maxHealth = 35,
		maxBlood = 9,
		bleedHealRate = 64,
		meleeTimerLength = 1,
		meleeDamage = 1,
		meleeBleedRateAdd = 7,

		attackDeadTargets = true
	}

	creatureTypes.scorpion = {
		displayName = "scorpion",
		tile = "S",
		colour = "yellow",
		fleshMaterialName = "fleshYellow",
		bloodMaterialName = "bloodGreen",
		size = 96,

		moveTimerLength = 7,
		sightDistance = 16,
		maxHealth = 20,
		maxBlood = 20,
		bleedHealRate = 32,
		meleeTimerLength = 3,
		meleeDamage = 8,
		meleeBleedRateAdd = 60,

		attackDeadTargets = true
	}

	creatureTypes.imp = {
		displayName = "imp",
		tile = "I",
		colour = "darkYellow",
		bloodMaterialName = "bloodRed",
		size = 48,

		moveTimerLength = 4,
		sightDistance = 17,
		maxHealth = 24,
		maxBlood = 24,
		bleedHealRate = 48,
		meleeTimerLength = 4,
		meleeDamage = 4,
		meleeBleedRateAdd = 16,
		meleeInstantBloodLoss = 1,
		shootAggressiveness = 0.25,

		hears = true,
		alertAction = "hiss",
		alertActionUsesVocalisation = true,
		vocalisationRange = 11,
		painDamageThreshold = 4,

		flying = true,
		attackDeadTargets = true,
		canOpenDoors = true,

		psychicDamageDeathPoint = 120,

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

	creatureTypes.demonicPriest = {
		displayName = "demonic priest",
		tile = "Å",
		colour = "darkBlue",
		bloodMaterialName = "bloodGreen",
		size = 128,

		moveTimerLength = 3,
		sightDistance = 18,
		maxHealth = 40,
		maxBlood = 24,
		bleedHealRate = 384,
		-- meleeTimerLength = 1,
		-- meleeDamage = 1,
		-- meleeBleedRateAdd = 0,
		-- meleeInstantBloodLoss = 1,

		engagesAtRange = true,
		preferredEngagementRange = 7,

		hears = true,
		alertAction = "chant",
		alertActionUsesVocalisation = true,
		vocalisationRange = 20,
		painDamageThreshold = 4,

		flying = true,
		attackDeadTargets = true,
		canOpenDoors = true,
		inventorySize = 1,

		shootAggressiveness = 1,
		wrongRangeShootAggressiveness = 0.2,
		telepathicMindAttackDamageRate = 1
	}

	creatureTypes.hellNoble = {
		displayName = "Hell noble",
		tile = "N",
		colour = "darkRed",
		bloodMaterialName = "bloodGreen",
		size = 256,

		moveTimerLength = 5,
		sightDistance = 18,
		maxHealth = 100,
		maxBlood = 100,
		bleedHealRate = 48,
		meleeTimerLength = 5,
		meleeDamage = 15,
		meleeBleedRateAdd = 64,
		meleeInstantBloodLoss = 5,
		shootAggressiveness = 0.2,

		inventorySize = 1,

		hears = true,
		alertAction = "warcry",
		alertActionUsesVocalisation = true,
		vocalisationRange = 18,
		painDamageThreshold = 16,

		chargeMelee = true,
		attackDeadTargets = true,
		canOpenDoors = true,

		psychicDamageDeathPoint = 120,

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
		size = 1024,

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

		hears = true,
		alertAction = "warcry",
		alertActionUsesVocalisation = true,
		vocalisationRange = 20,
		painDamageThreshold = 25,

		chargeMelee = true,
		canOpenDoors = true,
		attackDeadTargets = true,

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
		size = 192,

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
		attackDeadTargets = true,

		hears = true
	}
	creatureTypes.smallFish1 = {
		displayName = "small fish",
		tile = ",",
		colour = "darkGreen",
		bloodMaterialName = "bloodRed",
		size = 8,

		aquatic = true,
		cantMoveOnLand = true,
		moveTimerLength = nil,
		swimMoveTimerLength = 2,
		breathingTimerLength = 100,
		sightDistance = 9,
		maxHealth = 1,
		maxBlood = 1,
		bleedHealRate = 12,
		
		hears = true
	}
	creatureTypes.smallFish2 = {
		displayName = "small fish",
		tile = "α",
		colour = "darkCyan",
		bloodMaterialName = "bloodRed",
		size = 16,

		aquatic = true,
		cantMoveOnLand = true,
		moveTimerLength = nil,
		swimMoveTimerLength = 4,
		breathingTimerLength = 120,
		sightDistance = 9,
		maxHealth = 2,
		maxBlood = 2,
		bleedHealRate = 12,

		hears = true
	}

	creatureTypes.griefPhantom = {
		displayName = "rue phantom",
		tile = "¡",
		colour = "darkGrey",
		vanishOnNonGibDeath = true, -- To vanish on a gib death, noFlesh is also set
		noFlesh = true,
		size = 0,

		moveTimerLength = 2,
		sightDistance = 7,
		maxHealth = 1,
		meleeTimerLength = 3,
		meleeDamage = 0,
		meleeInstantBloodLoss = 3,

		engagesAtRange = true,
		preferredEngagementRange = 7,

		hears = false,
		alertAction = "scream",
		alertActionUsesVocalisation = true,
		vocalisationRange = 25,

		flying = true,

		shootAggressiveness = 1,
		wrongRangeShootAggressiveness = 0.2,
		projectileAbilities = {
			{
				name = "sorrowPulse",
				shootTime = 2,
				projectileTile = "¡",
				projectileColour = "lightGrey",
				projectileSubtickMoveTimerLength = 256,
				damage = 0,
				bleedRateAdd = 10,
				range = 12
			}
		}
	}

	creatureTypes.brutePhantom = {
		displayName = "brutal phantom",
		tile = "¡",
		colour = "darkCyan",
		vanishOnNonGibDeath = true, -- To vanish on a gib death, noFlesh is also set
		noFlesh = true,
		size = 0,

		moveTimerLength = 3,
		sightDistance = 3,
		maxHealth = 2,
		meleeTimerLength = 3,
		meleeDamage = 2,
		meleeInstantBloodLoss = 3,

		hears = false,
		alertAction = "scream",
		alertActionUsesVocalisation = true,
		vocalisationRange = 20,

		flying = true,

		pathfindingDistanceLimit = 10
	}

	creatureTypes.ogre = {
		displayName = "ogre",
		tile = "Ö",
		colour = "green",
		bloodMaterialName = "bloodRed",
		size = 192,

		moveTimerLength = 6,
		sightDistance = 15,
		maxHealth = 32,
		maxBlood = 32,
		bleedHealRate = 56,
		meleeTimerLength = 9,
		meleeDamage = 8,
		meleeBleedRateAdd = 12,
		meleeInstantBloodLoss = 0,

		hears = true,
		alertAction = "snarl",
		alertActionUsesVocalisation = true,
		vocalisationRange = 20,
		painDamageThreshold = 10,

		attackDeadTargets = true,
		canOpenDoors = true,

		psychicDamageDeathPoint = 60
	}

	creatureTypes.behemoth = {
		displayName = "behemoth",
		tile = "B",
		colour = "darkMagenta",
		bloodMaterialName = "bloodGreen",
		size = 256,

		moveTimerLength = 5,
		sightDistance = 17,
		maxHealth = 30,
		maxBlood = 30,
		bleedHealRate = 30,
		meleeTimerLength = 4,
		meleeDamage = 8,
		meleeBleedRateAdd = 16,
		meleeInstantBloodLoss = 1,
		shootAggressiveness = 0.25,

		hears = true,
		alertAction = "snarl",
		alertActionUsesVocalisation = true,
		vocalisationRange = 15,
		painDamageThreshold = 10,

		flying = true,
		attackDeadTargets = true,
		canOpenDoors = false,

		psychicDamageDeathPoint = 90,

		projectileAbilities = {
			{
				name = "fireball",
				shootTime = 4,
				projectileTile = "☼",
				projectileColour = "yellow",
				projectileSubtickMoveTimerLength = 256,
				damage = 6,
				bleedRateAdd = 4,
				range = 15
			}
		}
	}
end

return game
