-- TODO

return {
	sound = {
		volume = 0.75
	},
	graphics = {
		-- canvasScale = 1, -- Automatically filled with largest allowable size
		fullscreen = false
	},
	input = {
		initialKeyRepeatTimerLength = 0.2,
		keyRepeatTimerLength = 0.05,
		cursorButtonTimerLength = 0.25,
		autoOpenDoors = true
	},
	inputBindings = {
		viewJumpReach = "m",
		jump = "j",

		moveRightGroup = "d",
		moveUpRightGroup = "e",
		moveUpGroup = "w",
		moveUpLeftGroup = "q",
		moveLeftGroup = "a",
		moveDownLeftGroup = "z",
		moveDownGroup = "x",
		moveDownRightGroup = "c",

		lockOn = "l",
		-- clearCursor = "k",
		deselectGroup = "#",

		scrollBackwardsGroup = "[",
		scrollForwardsGroup = "]",

		shoot = "f",
		melee = "v",
		useHeldItem = "t",
		waitHold = "h",
		waitPrecise = "y",
		interact = "b",

		pickUpOrDropGroup = "g",
		handleInventorySlot1Group = "1",
		handleInventorySlot2Group = "2",
		handleInventorySlot3Group = "3",
		handleInventorySlot4Group = "4",
		handleInventorySlot5Group = "5",
		handleInventorySlot6Group = "6",
		handleInventorySlot7Group = "7",
		handleInventorySlot8Group = "8",
		handleInventorySlot9Group = "9",
		handleInventorySlotNoneGroup = "0",

		confirm = "space",

		toggleHistory = "tab",

		decreaseCanvasScale = "f9",
		increaseCanvasScale = "f10",
		toggleFullscreen = "f11",

		-- Modifiers
		moveAlternativeMode = "lalt",
		dodgeMode = "lctrl",
		moveCursorMode = "lshift",
		ammoListMode = "lalt",
		meleeChargeMode = "lshift",
		reloadMode = "r",
		dropMode = "lshift",
		unloadMode = "u",
		energyWeaponChargeMode = "lctrl",
		energyWeaponDischargeMode = "lalt",
		changeWornItemMode = "o",
		operateGunSide1 = "lctrl",
		operateGunSide2 = "lalt",
		rotateAmmoBackwardsMode = "lalt",
		rotateAmmoForwardsMode = "lctrl"
	}
}
