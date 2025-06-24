uniform sampler2D palette;
uniform vec2 foregroundColourCoords;
uniform vec2 backgroundColourCoords;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	return mix(
		Texel(palette, backgroundColourCoords, 0),
		Texel(palette, foregroundColourCoords, 0),
		Texel(image, textureCoords).g // Green works with black and white but also magenta and white
	);
}
