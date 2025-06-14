local game = {}

function game:loadItemTypes()
	local state = self.state
	local itemTypes = {}
	state.itemTypes = itemTypes

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
		magazineCapacity = 5
	}

	itemTypes.shotgunShell = {
		isAmmo = true,
		tile = "▬",
		ammoClass = "shellMedium",
		displayName = "shotgun shell",
		spread = 0.1,
		damage = 3,
		bulletCount = 9,
		bleedRateAdd = 4,
		instantBloodLoss = 1,
		projectileSubtickMoveTimerLength = 20,
		range = 16
	}

	itemTypes.penKnife = {
		tile = "`",
		displayName = "pen-knife",
		isMeleeWeapon = true,
		meleeDamage = 5,
		meleeBleedRateAdd = 25
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
end

return game
