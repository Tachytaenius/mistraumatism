uniform sampler2D palette;
uniform sampler2D font;
uniform ivec2 framebufferSize;
// uniform ivec2 charSize;
const int fontGlyphsSide = 16;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 cell = Texel(image, textureCoords).rgb;

	int textInfo = int(cell.r * 255 + 0.5);
	int fgInfo = int(cell.g * 255 + 0.5);
	int bgInfo = int(cell.b * 255 + 0.5);

	ivec2 foregroundColourCoords = ivec2(
		mod(fgInfo, 2),
		fgInfo / 2
	);
	ivec2 backgroundColourCoords = ivec2(
		mod(bgInfo, 2),
		bgInfo / 2
	);

	vec2 coordInCell = mod(textureCoords * vec2(framebufferSize), 1.0);
	ivec2 glyph = ivec2(mod(textInfo, fontGlyphsSide), textInfo / fontGlyphsSide);
	vec2 fontCoords = (vec2(glyph) + coordInCell) / (vec2(fontGlyphsSide, fontGlyphsSide));
	// if (coordInCell.x > 0.5) {
	// 	return vec4(vec3(textInfo / 255.0), 1.0);
	// }

	return mix(
		Texel(palette, vec2(backgroundColourCoords) / vec2(2, 8)),
		Texel(palette, vec2(foregroundColourCoords) / vec2(2, 8)),
		Texel(font, fontCoords).g // Green works with black and white but also magenta and white
	);
}
