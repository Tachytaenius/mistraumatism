local game = {}

function game:validateItemTypes()
	for itemTypeName, itemType in pairs(self.state.itemTypes) do
		if itemType.isHealItem and not itemType.healItemDeleteOnUse and itemType.stackable and not itemType.healItemEndlessUse then
			error(itemTypeName .. " is a healing item type that will set an entire stack of it to be used")
		end
	end
end

function game:loadItemTypes()
	local state = self.state
	local itemTypes = {}
	state.itemTypes = itemTypes

	-- NOTE: The gun behaviour variables (like noChamber or alteredMagazineUse) were designed to reach specific intended behaviours, and random combinations of the variables probably won't lead to good results.

	itemTypes.pistol = {
		isGun = true,
		tile = "¬",
		ammoClass = "bulletSmall",
		displayName = "pistol",
		extraSpread = nil,
		shotCooldownTimerLength = 2,
		operationTimerLength = 2,
		extraDamage = 1,
		manual = false,
		magazine = false,
		magazineRequired = true,
		magazineClass = "pistol",
		gunshotSoundRange = 14
	}

	itemTypes.pistolMagazine = {
		magazine = true,
		tile = "■",
		displayName = "pistol mag",
		magazineCapacity = 9,
		magazineClass = "pistol",
		ammoClass = "bulletSmall",
	}

	itemTypes.smallBullet = {
		isAmmo = true,
		stackable = true,
		maxStackSize = 4,
		tile = "i",
		ammoClass = "bulletSmall",
		displayName = "small bullet",
		spread = 0,
		damage = 11,
		bleedRateAdd = 10,
		instantBloodLoss = 2,
		bulletCount = 1,
		projectileSubtickMoveTimerLength = 18,
		range = 17,
		projectileTile = "∙",
		projectileColour = "darkGrey"
	}

	itemTypes.assaultRifle = {
		isGun = true,
		tile = "¬",
		ammoClass = "bulletMedium",
		displayName = "assault rifle",
		extraSpread = nil,
		shotCooldownTimerLength = 1,
		operationTimerLength = 3,
		extraDamage = 1,
		manual = false,
		magazine = false,
		magazineRequired = true,
		magazineClass = "rifle",
		gunshotSoundRange = 16
	}

	itemTypes.rifleMagazine = {
		magazine = true,
		tile = "■",
		displayName = "rifle mag",
		magazineCapacity = 30,
		magazineClass = "rifle",
		ammoClass = "bulletMedium",
	}

	itemTypes.mediumBullet = {
		isAmmo = true,
		stackable = true,
		maxStackSize = 4,
		tile = "ì",
		ammoClass = "bulletMedium",
		displayName = "medium bullet",
		spread = 0,
		damage = 14,
		bleedRateAdd = 24,
		instantBloodLoss = 3,
		bulletCount = 1,
		projectileSubtickMoveTimerLength = 16,
		range = 18,
		projectileTile = "∙",
		projectileColour = "darkGrey"
	}

	itemTypes.rotaryCannon = {
		isGun = true,
		tile = "∟",
		ammoClass = "bulletLarge",
		displayName = "rotary cannon",
		autoFeed = true, -- Electronically self-operating, or whatever. Fired rounds in the magazine don't jam!
		extraSpread = nil,
		shotCooldownTimerLength = 1,
		operationTimerLength = 1,
		extraDamage = 3,
		manual = false,
		magazine = false,
		magazineRequired = true,
		magazineClass = "largeBox",
		gunshotSoundRange = 15
	}

	itemTypes.largeBoxMagazine = {
		magazine = true,
		tile = "⌂",
		displayName = "large box mag",
		magazineCapacity = 99,
		magazineClass = "largeBox",
		ammoClass = "bulletLarge",
	}

	itemTypes.largeBullet = {
		isAmmo = true,
		stackable = true,
		maxStackSize = 3,
		tile = "î",
		ammoClass = "bulletLarge",
		displayName = "large bullet",
		spread = 0,
		damage = 18,
		bleedRateAdd = 96,
		instantBloodLoss = 5,
		bulletCount = 1,
		projectileSubtickMoveTimerLength = 14,
		range = 19,
		projectileTile = "∙",
		projectileColour = "darkGrey"
	}

	itemTypes.armArtillery = {
		isGun = true,
		tile = "∟",
		ammoClass = "bulletLarge",
		displayName = "arm artillery",
		autoFeed = true,
		extraSpread = nil,
		shotCooldownTimerLength = 1,
		-- shotsPerTick = 3,
		operationTimerLength = 1,
		manual = false,
		magazine = true,
		magazineCapacity = 99,
		gunshotSoundRange = 20
	}

	itemTypes.experimentalBullet = {
		isAmmo = true,
		stackable = true,
		maxStackSize = 3,
		tile = "î",
		ammoClass = "bulletLarge",
		displayName = "research round",
		spread = 0,
		damage = 20,
		bleedRateAdd = 120,
		instantBloodLoss = 6,
		bulletCount = 1,
		projectileSubtickMoveTimerLength = 512,
		projectileSubtickMoveTimerLengthChange = -40, -- Per tick
		projectileSubtickMoveTimerLengthMin = 16,
		range = 19,
		projectileTile = "∙",
		projectileColour = "yellow",
		projectileExplosionRadius = 1,
		projectileExplosionDamage = 50
	}

	itemTypes.pumpShotgun = {
		isGun = true,
		tile = "⌐",
		ammoClass = "shellMedium",
		displayName = "pump shotgun",
		extraSpread = nil,
		shotCooldownTimerLength = 1,
		operationTimerLength = 2,
		extraDamage = 1,
		manual = true,
		magazine = true,
		magazineCapacity = 4,
		gunshotSoundRange = 16
	}

	itemTypes.huntingShotgun = {
		isGun = true,
		displayAsDoubleShotgun = true, -- For held item info
		tile = "⌐",
		ammoClass = "shellMedium",
		displayName = "hunt shotgun",
		automaticEjection = true,
		extraSpread = 0.01,
		-- shotCooldownTimerLength = 1, -- Firing with both barrels doesn't work if this is present
		operationTimerLength = 3,
		extraDamage = 1,
		manual = true,
		noChamber = true,
		breakAction = true, -- Either in open (load/unload) mode or closed (fire (if cocked)) mode
		cycleOnBreakActionClose = true,
		alteredMagazineUse = "select", -- Implies multiple cocking components (number: magazineCapacity)
		magazine = true,
		magazineCapacity = 2,
		gunshotSoundRange = 16
	}

	itemTypes.sawnShotgun = {
		isGun = true,
		displayAsDoubleShotgun = true, -- For held item info
		tile = "⌐",
		ammoClass = "shellMedium",
		displayName = "sawn shotgun",
		extraSpread = 0.125,
		operationTimerLength = 2,
		extraDamage = 1,
		manual = true,
		noChamber = true,
		breakAction = true,
		cycleOnBreakActionClose = false, -- Manually-cocked external hammers
		manuallyOperateCockedStates = true,
		manualCockTime = 1,
		alteredMagazineUse = "select",
		magazine = true,
		magazineCapacity = 2,
		gunshotSoundRange = 16
	}

	itemTypes.buckshotShell = {
		isAmmo = true,
		stackable = true,
		maxStackSize = 4,
		tile = "▬",
		ammoClass = "shellMedium",
		displayName = "buckshot shell",
		spread = 0.1,
		damage = 3,
		bulletCount = 9,
		bleedRateAdd = 4,
		instantBloodLoss = 1,
		projectileSubtickMoveTimerLength = 20,
		range = 16,
		projectileTile = "∙",
		projectileColour = "darkGrey"
	}

	itemTypes.slugShell = {
		isAmmo = true,
		stackable = true,
		maxStackSize = 4,
		tile = "▬",
		ammoClass = "shellMedium",
		displayName = "slug shell",
		damage = 28,
		bulletCount = 1,
		bleedRateAdd = 100,
		instantBloodLoss = 7,
		projectileSubtickMoveTimerLength = 32,
		range = 18,
		projectileTile = "∙",
		projectileColour = "darkGrey"
	}

	itemTypes.rocketLauncher = {
		isGun = true,
		-- breakAction = true,
		-- operationTimerLength = 12,
		cycleDoesntMoveAmmo = true,
		tile = "I",
		ammoClass = "rocket",
		displayName = "RPG launcher",
		extraSpread = nil,
		noCocking = true,
		noChamber = true, -- Assumes magazine (can be inserted or integrated)
		alteredMagazineUse = "ignore", -- nil for normal use of magazine, or "ignore" or "select"
		manual = true,
		magazine = true,
		magazineCapacity = 1,
		gunshotSoundRange = 17
	}

	itemTypes.rocket = {
		isAmmo = true,
		stackable = false,
		noCasing = true,
		tile = "↑",
		projectileTile = "^",
		projectileColour = "darkYellow",
		ammoClass = "rocket",
		displayName = "rocket",
		damage = 40,
		bulletCount = 1,
		bleedRateAdd = 100,
		instantBloodLoss = 6,
		projectileSubtickMoveTimerLength = 192,
		projectileSubtickMoveTimerLengthChange = -40, -- Per tick
		projectileSubtickMoveTimerLengthMin = 16,
		range = 18,
		projectileExplosionRadius = 4,
		projectileExplosionDamage = 325,
		projectileExplosionProjectiles = {
			-- {
			-- 	count = 12,
			-- 	tile = "*",
			-- 	colour = "yellow",
			-- 	subtickMoveTimerLength = 200,
			-- 	subtickMoveTimerLengthChange = 56,
			-- 	subtickMoveTimerLengthMax = 1024,
			-- 	damage = 1,
			-- 	maxPierces = 1,
			-- 	bleedRateAdd = 40,
			-- 	instantBloodLoss = 1,
			-- 	range = 2,
			-- 	hitDeadEntities = true
			-- },
			-- {
			-- 	count = 4,
			-- 	tile = "☼",
			-- 	colour = "red",
			-- 	subtickMoveTimerLength = 240,
			-- 	subtickMoveTimerLengthChange = 32,
			-- 	subtickMoveTimerLengthMax = 1024,
			-- 	damage = 2,
			-- 	maxPierces = 2,
			-- 	bleedRateAdd = 56,
			-- 	instantBloodLoss = 1,
			-- 	range = 3,
			-- 	hitDeadEntities = true
			-- }
		},
		trailParticleInfo = {
			{
				count = 1,
				tile = "▒",
				foregroundColour = "darkGrey",
				backgroundColour = "black",
				lifetime = 1
			}
		}
	}

	itemTypes.railgun = {
		isGun = true,
		tile = "⌐",
		maxEnergy = 100,
		energyPerShot = 100,
		energyChargeRate = 2,
		energyDischargeRate = 3, -- Railgun to cell
		energyWeapon = true,
		displayName = "railgun",
		extraSpread = nil,
		shotCooldownTimerLength = 16,
		operationTimerLength = 1,
		manual = false,
		magazine = false,
		magazineRequired = true,
		worksInLiquid = true,
		magazineClass = "railgun",
		projectile = {
			projectileTile = "°",
			projectileColour = "white",
			spread = 0,
			damage = 200,
			bleedRateAdd = 1000,
			instantBloodLoss = 25,
			bulletCount = 1,
			projectileSubtickMoveTimerLength = 1,
			range = 22,
			maxPierces = 5,
			trailParticleInfo = {
				{
					count = 1,
					tile = "█",
					foregroundColour = "cyan",
					backgroundColour = "white",
					lifetime = 1
				}
			}
		},
		gunshotSoundRange = 18
	}

	itemTypes.railgunEnergyCell = {
		energyBattery = true,
		maxEnergy = 200,
		energyDischargeRate = 6,
		energyChargeRate = 5, -- Railgun to cell
		displayName = "railgun cell",
		tile = "Φ",
		swapColours = true,
		secondaryColour = "cyan",
		magazineClass = "railgun"
	}

	itemTypes.plasmaShotgun = {
		isGun = true,
		tile = "⌐",
		maxEnergy = 12,
		energyPerShot = 8,
		energyChargeRate = 1,
		energyDischargeRate = 1,
		energyWeapon = true,
		displayName = "plasma shotgun",
		extraSpread = nil,
		shotCooldownTimerLength = 4,
		operationTimerLength = 1,
		manual = false,
		magazine = false,
		magazineRequired = true,
		worksInLiquid = false,
		magazineClass = "plasma",
		projectile = {
			projectileTile = "*",
			projectileColour = "lightGrey",
			spread = 0.12,
			damage = 5,
			bleedRateAdd = 20,
			instantBloodLoss = 1,
			bulletCount = 12,
			projectileSubtickMoveTimerLength = 64,
			range = 14,
			maxPierces = 2,
			trailParticleInfo = {
				{
					count = 1,
					tile = "▓",
					foregroundColour = "cyan",
					backgroundColour = "lightGrey",
					lifetime = 1
				}
			}
		},
		gunshotSoundRange = 15
	}

	itemTypes.plasmaRifle = {
		isGun = true,
		tile = "⌐",
		maxEnergy = 2,
		energyPerShot = 2,
		energyChargeRate = 2,
		energyDischargeRate = 1,
		energyWeapon = true,
		displayName = "plasma rifle",
		extraSpread = nil,
		shotCooldownTimerLength = 1,
		operationTimerLength = 1,
		manual = false,
		magazine = false,
		magazineRequired = true,
		worksInLiquid = false,
		magazineClass = "plasma",
		projectile = {
			projectileTile = "☼",
			projectileColour = "lightGrey",
			spread = 0,
			damage = 16,
			bleedRateAdd = 100,
			instantBloodLoss = 3,
			bulletCount = 1,
			projectileSubtickMoveTimerLength = 48,
			range = 15,
			maxPierces = 3,
			trailParticleInfo = {
				{
					count = 1,
					tile = "▓",
					foregroundColour = "cyan",
					backgroundColour = "lightGrey",
					lifetime = 1
				}
			}
		},
		gunshotSoundRange = 14
	}

	itemTypes.plasmathrower = {
		isGun = true,
		tile = "⌐",
		maxEnergy = 1,
		energyPerShot = 1,
		energyChargeRate = 1,
		energyDischargeRate = 1,
		energyWeapon = true,
		displayName = "plasmathrower",
		extraSpread = nil,
		shotCooldownTimerLength = 1,
		operationTimerLength = 1,
		manual = false,
		magazine = false,
		magazineRequired = true,
		worksInLiquid = false,
		magazineClass = "plasma",
		projectile = {
			projectileTile = nil,
			projectileColour = "yellow",
			spread = 0.5,
			damage = 1,
			bleedRateAdd = 1,
			instantBloodLoss = 0,
			bulletCount = 8,
			projectileSubtickMoveTimerLength = 128,
			range = 6,
			maxPierces = 1,
			trailParticleInfo = {
				{
					count = 1,
					tile = "▒",
					foregroundColour = "yellow",
					backgroundColour = "red",
					lifetime = 3
				}
			}
		},
		gunshotSoundRange = 5
	}

	itemTypes.plasmaEnergyCell = {
		energyBattery = true,
		maxEnergy = 64,
		energyDischargeRate = 2,
		energyChargeRate = 2, -- Weapon back into cell
		displayName = "plasma cell",
		tile = "=",
		swapColours = true,
		secondaryColour = "darkCyan",
		magazineClass = "plasma"
	}

	itemTypes.boxCutter = {
		tile = "`",
		displayName = "box cutter",
		isMeleeWeapon = true,
		meleeDamage = 5,
		meleeBleedRateAdd = 15
	}

	itemTypes.dagger = {
		tile = "`",
		displayName = "dagger",
		isMeleeWeapon = true,
		meleeDamage = 6,
		meleeBleedRateAdd = 18
	}

	itemTypes.combatKnife = {
		tile = "`",
		displayName = "combat knife",
		isMeleeWeapon = true,
		meleeDamage = 8,
		meleeBleedRateAdd = 24
	}

	itemTypes.scythe = {
		tile = "ƒ",
		displayName = "scythe",
		isMeleeWeapon = true,
		meleeDamage = 7,
		meleeBleedRateAdd = 32,
		meleeTimerAdd = 5
	}

	itemTypes.crowbar = {
		tile = "⌠",
		displayName = "crowbar",
		isMeleeWeapon = true,
		meleeDamage = 6,
		meleeBleedRateAdd = 2
	}

	itemTypes.note = {
		tile = "≡",
		displayName = "note",
		interactable = true,
		swapColours = true,
		interactionType = state.interactionTypes.readable
	}

	itemTypes.flower = {
		tile = " ",
		readMaterialTileField = "flowerTile",
		displayName = "flower",
		stackable = true,
		maxStackSize = 6
	}
	itemTypes.sapling = {
		tile = "τ",
		displayName = "sapling",
		stackable = true,
		maxStackSize = 3
	}
	itemTypes.vines = {
		tile = "½",
		displayName = "vines",
		stackable = true,
		maxStackSize = 4
	}

	itemTypes.labTable = {
		noPickUp = true,
		tile = "╥",
		displayName = "lab table"
	}
	itemTypes.desk = {
		noPickUp = true,
		tile = "╥",
		displayName = "desk"
	}
	itemTypes.officeChair = {
		noPickUp = true,
		tile = "h",
		displayName = "office chair"
	}
	itemTypes.throne = {
		noPickUp = true,
		tile = "H",
		displayName = "throne"
	}
	itemTypes.bedsideTable = {
		noPickUp = true,
		tile = "╥",
		displayName = "bedside table"
	}
	itemTypes.bed = {
		noPickUp = true,
		tile = "Θ",
		displayName = "bed"
	}
	itemTypes.toilet = {
		noPickUp = true,
		-- tile = "Ω",
		tile = "º",
		displayName = "toilet"
	}
	itemTypes.computer = {
		noPickUp = true,
		tile = "■",
		swapColours = true,
		displayName = "computer"
	}
	itemTypes.filingCabinet = {
		noPickUp = true,
		tile = "≡",
		swapColours = true,
		displayName = "filing cabinet"
	}

	itemTypes.statue1 = {
		noPickUp = true,
		tile = "≥",
		displayName = "statue",
		interactable = true,
		interactionType = state.interactionTypes.observable
	}
	itemTypes.statue2 = {
		noPickUp = true,
		tile = "≤",
		displayName = "statue",
		interactable = true,
		interactionType = state.interactionTypes.observable
	}
	itemTypes.statue3 = {
		noPickUp = true,
		tile = "±",
		displayName = "statue",
		interactable = true,
		interactionType = state.interactionTypes.observable
	}
	itemTypes.altar = {
		noPickUp = true,
		tile = "▄",
		displayName = "altar"
	}
	itemTypes.gallows = {
		noPickUp = true,
		tile = "Γ",
		displayName = "gallows",
		anchorsOverPits = true
	}
	itemTypes.wallShackles = {
		noPickUp = true,
		tile = "∞",
		displayName = "wall shackles",
		anchorsOverPits = true
	}
	itemTypes.ornateChair = {
		noPickUp = true,
		tile = "h",
		displayName = "ornate chair"
	}
	itemTypes.ornateDesk = {
		noPickUp = true,
		tile = "╥",
		displayName = "ornate desk"
	}
	itemTypes.ornateDoor = {
		isDoor = true,
		anchorsOverPits = true,
		interactable = true,
		interactionType = state.interactionTypes.door,
		noPickUp = true,
		doorWindow = false,
		tile = "│",
		openTile = "╟",
		displayName = "ornate door",
		stateChangeSoundRange = 5,
		dynamicDoorTileInfo = {closedLineNumber = 1, openLineNumber = 2, perpendicularLineNumberOpen = 1} -- Only calculated on level generation finish
	}
	itemTypes.heavyDoor = {
		isDoor = true,
		anchorsOverPits = true,
		interactable = true,
		interactionType = state.interactionTypes.heavyDoor,
		noPickUp = true,
		doorWindow = false,
		tile = "│",
		openTile = "╟",
		displayName = "heavy door",
		stateChangeSoundRange = 12,
		dynamicDoorTileInfo = {closedLineNumber = 1, openLineNumber = 2, perpendicularLineNumberOpen = 1}
	}

	itemTypes.door = {
		isDoor = true,
		anchorsOverPits = true,
		interactable = true,
		interactionType = state.interactionTypes.door,
		noPickUp = true,
		doorWindow = false,
		tile = "│",
		openTile = "╟",
		displayName = "door",
		stateChangeSoundRange = 4,
		dynamicDoorTileInfo = {closedLineNumber = 1, openLineNumber = 2, perpendicularLineNumberOpen = 1}
	}
	itemTypes.doorWindow = {
		isDoor = true,
		anchorsOverPits = true,
		interactable = true,
		interactionType = state.interactionTypes.door,
		noPickUp = true,
		doorWindow = true,
		tile = "│",
		openTile = "╟",
		displayName = "windowed door",
		stateChangeSoundRange = 4,
		dynamicDoorTileInfo = {closedLineNumber = 1, openLineNumber = 2, perpendicularLineNumberOpen = 1}
	}
	itemTypes.airlockDoor = {
		isDoor = true,
		anchorsOverPits = true,
		noPickUp = true,
		doorWindow = false,
		tile = "╪",
		openTile = "╡",
		displayName = "airlock door",
		stateChangeSoundRange = 14
	}
	itemTypes.castleDoorLeft = {
		isDoor = true,
		anchorsOverPits = true,
		noPickUp = true,
		doorWindow = false,
		tile = "║",
		openTile = "▐", -- Material colour will be on the left side because of swapColours
		swapColours = true,
		displayName = "castle door",
		stateChangeSoundRange = 22
	}
	itemTypes.castleDoorRight = {
		isDoor = true,
		anchorsOverPits = true,
		noPickUp = true,
		doorWindow = false,
		tile = "║",
		openTile = "▌",
		swapColours = true,
		displayName = "castle door",
		stateChangeSoundRange = 22
	}
	itemTypes.bench = {
		noPickUp = true,
		tile = "╤",
		displayName = "bench"
	}
	itemTypes.bigPlantPot = {
		noPickUp = true,
		tile = "u",
		displayName = "big plant pot"
	}

	itemTypes.button = {
		isButton = true,
		noPickUp = true,
		tile = "•",
		activeTile = "○",
		displayName = "button",
		interactable = true,
		interactionType = state.interactionTypes.button,
		stateChangeSoundRange = 2
	}

	itemTypes.lever = {
		isLever = true,
		noPickUp = true,
		tile = "ò",
		activeTile = "ó",
		displayName = "lever",
		interactable = true,
		interactionType = state.interactionTypes.lever,
		stateChangeSoundRange = 2
	}

	itemTypes.smallBook = {
		tile = "∞",
		displayName = "small book",
		interactable = true,
		interactionType = state.interactionTypes.observable
	}
	itemTypes.book = {
		tile = "∞",
		displayName = "book",
		interactable = true,
		interactionType = state.interactionTypes.observable
	}
	itemTypes.leverBook = {
		tile = "∞",
		activeTile = "φ",
		displayName = "book",
		interactable = true,
		interactionType = state.interactionTypes.lever,
		isLever = true,
		inactiveHidden = true, -- Hide "inactive" status
		onActivateMessage = "The book was a hidden lever!",
		noPickUp = true,
		stateChangeSoundRange = 2
	}
	itemTypes.largeBook = {
		tile = "∞",
		displayName = "large book",
		interactable = true,
		interactionType = state.interactionTypes.observable
	}

	itemTypes.bandage = {
		isHealItem = true,
		tile = "σ",
		displayName = "bandage",
		stackable = true,
		maxStackSize = 3,
		interactable = true,
		healItemHealthAdd = 1,
		healingRequiresHolding = true,
		healItemUseTimer = 16,
		healItemUseTimerOnGround = nil,
		healItemBleedRateSubtract = 15,
		healItemDeleteOnUse = true,
		interactionType = state.interactionTypes.healItem
	}
	itemTypes.smallMedkit = {
		isHealItem = true,
		tile = "+",
		displayName = "small medkit", 
		swapColours = true,
		secondaryColour = "white",
		interactable = true,
		healingRequiresHolding = false,
		healItemUseTimer = 22,
		healItemUseTimerOnGround = 25,
		healItemBleedRateSubtract = 20,
		healItemHealthAdd = 5,
		healItemBloodReplenish = 3,
		healItemDeleteOnUse = false,
		interactionType = state.interactionTypes.healItem
	}
	itemTypes.largeMedkit = { 
		isHealItem = true,
		tile = "±",
		displayName = "large medkit",
		swapColours = true,
		secondaryColour = "white",
		stackable = false,
		interactable = true,
		healingRequiresHolding = false,
		healItemUseTimer = 24,
		healItemUseTimerOnGround = 27,
		healItemBleedRateSubtract = 40,
		healItemHealthAdd = 10,
		healItemBloodReplenish = 8,
		healItemDeleteOnUse = false,
		interactionType = state.interactionTypes.healItem
	}
	itemTypes.healingRune = {
		isHealItem = true,
		tile = "♥",
		displayName = "healing rune",
		swapColours = true,
		secondaryColour = "magenta",
		interactable = true,
		healingRequiresHolding = true,
		healItemUseTimer = 8,
		healItemUseTimerOnGround = nil,
		healItemBleedRateSubtract = "all",
		healItemHealthAdd = "all",
		healItemBloodReplenish = "all",
		healItemAirTimeRefill = "all",
		healItemDeleteOnUse = true,
		interactionType = state.interactionTypes.healItem,
		healItemMessage = "You feel so much better!",
		healItemMessageColour = "green"
	}
	-- TODO: Stimpacks for short-term mitigation of shock and exhaustion?

	itemTypes.knightlyArmour = {
		tile = "┬",
		displayName = "knight armour",
		swapColours = true,
		wearable = true,
		armourDefence = 3,
		armourDurability = 10
	}
	itemTypes.tacticalArmour = {
		tile = "Ω",
		displayName = "tactic armour",
		wearable = true,
		armourDefence = 4,
		armourDurability = 20
	}

	itemTypes.ornateKey = {
		tile = "♪",
		displayName = "ornate key",
		isKey = true
	}
	itemTypes.keycard = {
		tile = "■",
		displayName = "keycard",
		isKey = true
	}

	itemTypes.longsword = {
		tile = "/",
		displayName = "longsword",
		isMeleeWeapon = true,
		meleeDamage = 8,
		meleeBleedRateAdd = 24
	}
	
	itemTypes.toothOutcrop = {
		tile = "▲",
		displayName = "tooth outcrop",
		noPickUp = true
	}
	itemTypes.boneOutcrop = {
		tile = "¶",
		displayName = "bone outcrop",
		noPickUp = true
	}
	itemTypes.hellTendril = {
		tile = "⌠",
		displayName = "hell tendril",
		noPickUp = true
	}

	itemTypes.crozier = {
		tile = "⌠",
		displayName = "crozier",
		isMeleeWeapon = true,
		meleeDamage = 6,
		meleeBleedRateAdd = 2
	}

	itemTypes.coffin = {
		tile = "0",
		displayName = "coffin",
		noPickUp = true
	}

	self:validateItemTypes()
end

return game
