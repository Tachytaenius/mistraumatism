local game = {}

function game:loadWEaponTypes()
	local state = self.state
	local weaponTypes = {}
	state.weaponTypes = weaponTypes

	weaponTypes.pistol = {
		bulletCount = 1,
		damage = 4,
		projectileSpeed = 1,
		projectileSpeedVariation = 0.1,
	}
end

return game
