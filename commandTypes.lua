local util = require("util")

local commands = {
	jump = {type = "pressed"},
	viewJumpReach = {type = "hold"},

	lockOn = {type = "pressed"},
	-- clearCursor = {type = "pressed"},
	spawnCursor = {type = "pressed"},

	shoot = {type = "pressed"},
	melee = {type = "pressed"},
	useHeldItem = {type = "pressed"},
	interact = {type = "pressed"},

	menu = {type = "pressed"},
	confirm = {type = "pressed"},

	toggleHistory = {type = "pressed"},

	toggleFullscreen = {type = "pressed"},
	decreaseCanvasScale = {type = "pressed"},
	increaseCanvasScale = {type = "pressed"},

	waitHold = {type = "hold"},
	waitPrecise = {type = "pressed"},
}

local commandGroups = {
	deselectGroup = {isGroup = true,
		deselectTarget = {type = "pressed"},
		deselectAmmo = {type = "pressed"}
	},

	scrollBackwardsGroup = {isGroup = true,
		scrollListBackwards = {type = "repeat", modifiers = {}},
		scrollAmmoListBackwards = {type = "repeat", modifiers = {"ammoListMode"}}
	},
	scrollForwardsGroup = {isGroup = true,
		scrollListForwards = {type = "repeat", modifiers = {}},
		scrollAmmoListForwards = {type = "repeat", modifiers = {"ammoListMode"}}
	},

	pickUpOrDropGroup = {isGroup = true,
		pickUp = {type = "repeat"},
		drop = {type = "repeat", modifiers = {"dropMode"}}
	}
}

local function newDirGroup(dir)
	local move = "move" .. dir
	local moveCursor = "moveCursor" .. dir
	commandGroups[move .. "Group"] = {isGroup = true,
		[move] = {type = "hold"},
		[moveCursor] = {type = "repeat", modifiers = {"moveCursorMode"}},
	}
end
newDirGroup("Right")
newDirGroup("UpRight")
newDirGroup("Up")
newDirGroup("UpLeft")
newDirGroup("Left")
newDirGroup("DownLeft")
newDirGroup("Down")
newDirGroup("DownRight")

for num = 1, 9 do
	commandGroups["handleInventorySlot" .. num .. "Group"] = {isGroup = true,
		["reloadFromInventorySlot" .. num] = {type = "repeat", modifiers = {"reloadMode"}},
		["unloadToInventorySlot" .. num] = {type = "repeat", modifiers = {"unloadMode"}},
		["doffItemToInventorySlot" .. num] = {type = "pressed", modifiers = {"changeWornItemMode"}},
		["swapToInventorySlot" .. num] = {type = "pressed"}
	}
end
commandGroups.handleInventorySlotNoneGroup = {isGroup = true,
	doffItemToInventorySlotNone = {type = "pressed", modifiers = {"changeWornItemMode"}},
	unloadToInventorySlotNone = {type = "repeat", modifiers = {"unloadMode"}},
	deselectInventorySlot = {type = "pressed"}
}

for groupName, commandGroup in pairs(commandGroups) do
	commandGroup.relevantModifiers = {}
	commandGroup.groupName = groupName
	for commandName, commandValue in pairs(commandGroup) do
		if commandName == "isGroup" or commandName == "relevantModifiers" or commandName == "groupName" then
			goto continue
		end
		commandValue.group = commandGroup
		commands[commandName] = commandValue
		for _, modifier in ipairs(commandValue.modifiers or {}) do
			commandGroup.relevantModifiers[modifier] = true
		end
		commandValue.modifiers = util.arrayToSet(commandValue.modifiers or {})
	    ::continue::
	end
end

return {
	commands = commands,
	commandGroups = commandGroups,
	modifiers = {
		dodgeMode = true,
		moveAlternativeMode = true,
		moveCursorMode = true,
		meleeChargeMode = true,
		ammoListMode = true,
		dropMode = true,
		reloadMode = true,
		unloadMode = true,
		energyWeaponChargeMode = true,
		energyWeaponDischargeMode = true,
		changeWornItemMode = true,
		operateGunSide1 = true,
		operateGunSide2 = true,
		rotateAmmoBackwardsMode = true,
		rotateAmmoForwardsMode = true
	},
	modifierGroups = {
		{"reloadMode", "unloadMode"},
		{"energyWeaponChargeMode", "energyWeaponDischargeMode"},
		{"operateGunSide1", "operateGunSide2"},
		{"rotateAmmoBackwardsMode", "rotateAmmoForwardsMode"}
	}
}
