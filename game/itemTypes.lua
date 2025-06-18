local game = {}

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
		magazineClass = "pistol"
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
		damage = 12,
		bleedRateAdd = 10,
		instantBloodLoss = 2,
		bulletCount = 1,
		projectileSubtickMoveTimerLength = 18,
		range = 17
	}

	itemTypes.mediumBullet = {
		isAmmo = true,
		stackable = true,
		maxStackSize = 4,
		tile = "ì",
		ammoClass = "bulletMedium",
		displayName = "medium bullet",
		spread = 0,
		damage = 16,
		bleedRateAdd = 24,
		instantBloodLoss = 3,
		bulletCount = 1,
		projectileSubtickMoveTimerLength = 16,
		range = 18
	}

	itemTypes.rotaryCannon = {
		isGun = true,
		tile = "∟",
		ammoClass = "bulletLarge",
		displayName = "rotary cannon",
		autoFeed = true, -- Electronically self-operating, or whatever. Fired rounds in the magazine don't jam!
		extraSpread = nil,
		shotCooldownTimerLength = 1,
		-- shotsPerTick = 3,
		operationTimerLength = 1,
		extraDamage = 3,
		manual = false,
		magazine = false,
		magazineRequired = true,
		magazineClass = "largeBox"
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
		damage = 20,
		bleedRateAdd = 96,
		instantBloodLoss = 5,
		bulletCount = 1,
		projectileSubtickMoveTimerLength = 14,
		range = 19
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
		magazineCapacity = 4
	}

	itemTypes.huntingShotgun = {
		isGun = true,
		displayAsDoubleShotgun = true, -- For held item info
		tile = "⌐",
		ammoClass = "shellMedium",
		displayName = "hunt shotgun",
		automaticEjection = true,
		extraSpread = 0.05,
		-- shotCooldownTimerLength = 1, -- Firing with both barrels doesn't work if this is present
		operationTimerLength = 7,
		extraDamage = 1,
		manual = true,
		noChamber = true,
		breakAction = true, -- Either in open (load/unload) mode or closed (fire (if cocked)) mode
		alteredMagazineUse = "select", -- Implies multiple cocking components (number: magazineCapacity)
		magazine = true,
		magazineCapacity = 2
	}

	itemTypes.sawnShotgun = {
		isGun = true,
		displayAsDoubleShotgun = true, -- For held item info
		tile = "⌐",
		ammoClass = "shellMedium",
		displayName = "sawn shotgun",
		extraSpread = 0.25,
		operationTimerLength = 6,
		extraDamage = 1,
		manual = true,
		noChamber = true,
		breakAction = true,
		alteredMagazineUse = "select",
		magazine = true,
		magazineCapacity = 2
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
		range = 16
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
		range = 18
	}

	itemTypes.rocketLauncher = {
		isGun = true,
		-- breakAction = true,
		-- operationTimerLength = 12,
		cycleDoesntMoveAmmo = true,
		tile = "/",
		ammoClass = "rocket",
		displayName = "RPG launcher",
		extraSpread = nil,
		noCocking = true,
		noChamber = true, -- Assumes magazine (can be inserted or integrated)
		alteredMagazineUse = "ignore", -- nil for normal use of magazine, or "ignore" or "select"
		manual = true,
		magazine = true,
		magazineCapacity = 1
	}

	itemTypes.rocket = {
		isAmmo = true,
		stackable = false,
		noCasing = true,
		tile = "↑",
		projectileTile = "^",
		projectileColour = "yellow",
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
		projectileExplosionRadius = 3,
		projectileExplosionDamage = 400,
		projectileExplosionProjectiles = {
			{
				count = 8,
				tile = "*",
				colour = "yellow",
				subtickMoveTimerLength = 200,
				subtickMoveTimerLengthChange = 56,
				subtickMoveTimerLengthMax = 1024,
				damage = 1,
				maxPierces = 1,
				bleedRateAdd = 40,
				instantBloodLoss = 1,
				range = 2,
				hitDeadEntities = true
			},
			{
				count = 2,
				tile = "☼",
				colour = "red",
				subtickMoveTimerLength = 240,
				subtickMoveTimerLengthChange = 32,
				subtickMoveTimerLengthMax = 1024,
				damage = 4,
				maxPierces = 2,
				bleedRateAdd = 56,
				instantBloodLoss = 1,
				range = 3,
				hitDeadEntities = true
			}
		}
	}

	itemTypes.boxCutter = {
		tile = "`",
		displayName = "box cutter",
		isMeleeWeapon = true,
		meleeDamage = 5,
		meleeBleedRateAdd = 15
	}

	itemTypes.note = {
		tile = "■",
		displayName = "note",
		interactable = true,
		interactionType = state.interactionTypes.readable
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

	itemTypes.door = {
		isDoor = true,
		interactable = true,
		interactionType = state.interactionTypes.door,
		noPickUp = true,
		doorWindow = false,
		tile = "│",
		openTile = "╟",
		displayName = "door"
	}
	itemTypes.doorWindow = {
		isDoor = true,
		interactable = true,
		interactionType = state.interactionTypes.door,
		noPickUp = true,
		doorWindow = true,
		tile = "│",
		openTile = "╟",
		displayName = "windowed door"
	}
	itemTypes.airlockDoor = {
		isDoor = true,
		noPickUp = true,
		doorWindow = false,
		tile = "╪",
		openTile = "╡",
		displayName = "airlock door"
	}

	itemTypes.button = {
		isButton = true,
		noPickUp = true,
		tile = "•",
		activeTile = "○",
		displayName = "button",
		interactable = true,
		interactionType = state.interactionTypes.button
	}
end

return game
