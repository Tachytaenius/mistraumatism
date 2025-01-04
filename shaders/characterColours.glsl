uniform sampler2D palette;
uniform ivec2 foregroundColourPosition;
uniform ivec2 backgroundColourPosition;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	return  mix(
		texelFetch(palette, backgroundColourPosition, 0),
		texelFetch(palette, foregroundColourPosition, 0),
		Texel(image, textureCoords).g // Green works with black and white but also magenta and white
	);
}
