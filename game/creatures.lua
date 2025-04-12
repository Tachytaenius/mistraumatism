local game = {}

function game:loadCreatureTypes()
	local state = self.state
	local creatureTypes = {}
	state.creatureTypes = creatureTypes

	creatureTypes.human = {
		tile = "@",
		colour = "white",

		speed = 8,

		maxHealth = 12, -- I was gonna make a whole complicated gore system using graph theory for body parts and stuff
		maxBlood = 2
	}
end

return game
