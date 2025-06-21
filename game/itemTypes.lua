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
		magazineCapacity = 2
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
				count = 12,
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
				count = 4,
				tile = "☼",
				colour = "red",
				subtickMoveTimerLength = 240,
				subtickMoveTimerLengthChange = 32,
				subtickMoveTimerLengthMax = 1024,
				damage = 2,
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

	itemTypes.dagger = {
		tile = "`",
		displayName = "dagger",
		isMeleeWeapon = true,
		meleeDamage = 6,
		meleeBleedRateAdd = 18
	}

	itemTypes.scythe = {
		tile = "ƒ",
		displayName = "scythe",
		isMeleeWeapon = true,
		meleeDamage = 10,
		meleeBleedRateAdd = 32,
		meleeTimerAdd = 4
	}

	itemTypes.crowbar = {
		tile = "⌠",
		displayName = "crowbar",
		isMeleeWeapon = true,
		meleeDamage = 6,
		meleeBleedRateAdd = 2
	}

	itemTypes.note = {
		tile = "■",
		displayName = "note",
		interactable = true,
		interactionType = state.interactionTypes.readable
	}

	itemTypes.flower = {
		tile = "♣",
		displayName = "flower",
		stackable = true,
		maxStackSize = 6 
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
		tile = "☺",
		displayName = "statue",
		interactable = true,
		interactionType = state.interactionTypes.observable
	}
	itemTypes.statue2 = {
		noPickUp = true,
		tile = "☻",
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
		interactable = true,
		interactionType = state.interactionTypes.door,
		noPickUp = true,
		doorWindow = false,
		tile = "│",
		openTile = "╟",
		displayName = "ornate door"
	}
	itemTypes.heavyDoor = {
		isDoor = true,
		interactable = true,
		interactionType = state.interactionTypes.heavyDoor,
		noPickUp = true,
		doorWindow = false,
		tile = "│",
		openTile = "╟",
		displayName = "heavy door"
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
	itemTypes.castleDoorLeft = {
		isDoor = true,
		noPickUp = true,
		doorWindow = false,
		tile = "║",
		openTile = "▐", -- Material colour will be on the left side because of swapColours
		swapColours = true,
		displayName = "castle door"
	}
	itemTypes.castleDoorRight = {
		isDoor = true,
		noPickUp = true,
		doorWindow = false,
		tile = "║",
		openTile = "▌",
		swapColours = true,
		displayName = "castle door"
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

	itemTypes.lever = {
		isLever = true,
		noPickUp = true,
		tile = "ò",
		activeTile = "ó",
		displayName = "lever",
		interactable = true,
		interactionType = state.interactionTypes.lever
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
		noPickUp = true
	}
	itemTypes.largeBook = {
		tile = "∞",
		displayName = "large book",
		interactable = true,
		interactionType = state.interactionTypes.observable
	}
end

return game
