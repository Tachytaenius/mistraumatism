local utf8 = require("utf8")

local consts = {}

consts.loveIdentity = "mistraumatism"
consts.loveVersion = "11.5"
consts.windowTitle = "Mistraumatism"

local null = utf8.char(0)
local nonBreakingSpace = utf8.char(160)
consts.cp437String =
	null .. "☺☻♥♦♣♠•◘○◙♂♀♪♫☼" ..
	"►◄↕‼¶§▬↨↑↓→←∟↔▲▼" ..
	" !\"#$%&\'()*+,-./" ..
	"0123456789:;<=>?" ..
	"@ABCDEFGHIJKLMNO" ..
	"PQRSTUVWXYZ[\\]^_" ..
	"`abcdefghijklmno" ..
	"pqrstuvwxyz{|}~⌂" ..
	"ÇüéâäàåçêëèïîìÄÅ" ..
	"ÉæÆôöòûùÿÖÜ¢£¥₧ƒ" ..
	"áíóúñÑªº¿⌐¬½¼¡«»" ..
	"░▒▓│┤╡╢╖╕╣║╗╝╜╛┐" ..
	"└┴┬├─┼╞╟╚╔╩╦╠═╬╧" ..
	"╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀" ..
	"αßΓπΣσµτΦΘΩδ∞φε∩" ..
	"≡±≥≤⌠⌡÷≈°∙·√ⁿ²■" .. nonBreakingSpace

consts.cp437Map = {} -- cp437 codepoint <-> utf8 char
local i = 0
for _, code in utf8.codes(consts.cp437String) do
	local char = utf8.char(code)
	consts.cp437Map[char] = i
	consts.cp437Map[i] = char
	i = i + 1
end

consts.cp437Count = 256

consts.fontWidthCharacters, consts.fontHeightCharacters = 16, 16

consts.colourCoords = {
	black = {0, 0}, darkGrey = {1, 0},
	darkRed = {0, 1}, red = {1, 1},
	darkYellow = {0, 2}, yellow = {1, 2},
	darkGreen = {0, 3}, green = {1, 3},
	darkCyan = {0, 4}, cyan = {1, 4},
	darkBlue = {0, 5}, blue = {1, 5},
	darkMagenta = {0, 6}, magenta = {1, 6},
	lightGrey = {0, 7}, white = {1, 7}
}

consts.colourCoordsTexel = {}
for colour, coord in pairs(consts.colourCoords) do
	consts.colourCoordsTexel[colour] = {coord[1] / 2, coord[2] / 8}
end

consts.darkerColours = {}
for name, coords in pairs(consts.colourCoords) do
	if coords[1] == 1 then
		for otherName, otherCoords in pairs(consts.colourCoords) do
			if otherCoords[2] == coords[2] and otherCoords[1] ~= coords[1] then
				consts.darkerColours[name] = otherName
			end
		end
	end
end
consts.darkerColours.lightGrey = "darkGrey" -- Extra

consts.fixedUpdateTickLength = 0.03125

consts.diagonal = 1 / math.sqrt(2) -- Sine of 45 degrees, sqrt(2) / 2, or both components of the normalisation result of the vector (1, 1)
consts.inverseDiagonal = math.sqrt(2)

consts.projectileSubticks = 256

consts.spatterThreshold1 = 1
consts.spatterThreshold2 = 4
consts.spatterThreshold3 = 7
consts.spatterThreshold4 = 10

consts.tau = math.pi * 2

consts.spreadRetargetDistance = 128

consts.initialKeyRepeatTimerLength = 0.2
consts.keyRepeatTimerLength = 0.05

consts.entityPathfindingOccupiedCostMultiplier = 16

consts.bleedTimerLength = 1536
consts.bleedHealTimerLength = 512
consts.maxBleedingAmount = 900
consts.drownTimerRecoveryRate = 4
consts.gibFleshTiles = {"²", "ⁿ"}
consts.explosionGradient = {"black", "darkGrey", "lightGrey", "darkYellow", "yellow", "white"}
consts.explosionGradientMax = 255 -- Seems to protect against non-uniformities in the gradient? During my specific testing setup, anyway. Which is as follows:
-- Some random coords in a test map
-- for xo = 0, 26 do
-- 	self:getTile(7+xo,15).explosionInfo=nil
-- 	self:explode(7 + xo, 15, 0, xo * 0.25 * (consts.explosionGradientMax / #consts.explosionGradient), state.player)
-- end
consts.explosionVisualDiminishRate = 0.5
consts.explosionVisualRapidDiminishMultiplier = 8
consts.explosionVisualRapidDiminishThreshold = 40

consts.itemDefaultMaxStackSize = 9

return consts
