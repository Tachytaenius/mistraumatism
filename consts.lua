local utf8 = require("utf8")

local consts = {}

consts.loveIdentity = "shooter-prototyping"
consts.loveVersion = "12.0"
consts.windowTitle = "Shooter Prototyping"

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

consts.fixedUpdateTickLength = 0.03125

consts.diagonal = 1 / math.sqrt(2) -- Sine off 45 degrees, sqrt(2) / 2, or both components of the normalisation result of the vector 1, 1

return consts
