varying vec3 fragmentPosition;
varying vec2 fragmentTexCoord;
varying vec3 fragmentNormal;

#ifdef VERTEX

// attribute vec2 VertexTexCoord;
attribute vec3 VertexNormal;

uniform mat4 modelToClip;
uniform mat4 modelToWorld;

vec4 position(mat4 loveTransform, vec4 homogenVertexPos) {
	fragmentTexCoord = VertexTexCoord.xy;
	fragmentNormal = VertexNormal;
	fragmentPosition = vec3(modelToWorld * homogenVertexPos);
	return modelToClip * homogenVertexPos;
}

#endif

#ifdef PIXEL

uniform sampler2D baseColourTex;
uniform vec3 cameraPos;
uniform vec3 sunlightDir;
uniform vec3 sunlight;
uniform vec3 skyColour;
uniform vec3 lightPos;
const float fogDist = 25.0;

void effect() {
	vec3 fragBaseColour = Texel(baseColourTex, fragmentTexCoord).rgb;

	// vec3 fragToLight = (lightPos - fragmentPosition);
	// float dist = length(fragToLight);
	// const vec3 light = vec3(1.0);
	// vec3 lightDir = normalize(fragToLight);

	vec3 lightDir = sunlightDir;
	vec3 light = sunlight;
	float dist = 1.0;

	vec3 fragToCam = cameraPos - fragmentPosition;
	float fragDist = length(fragToCam);

	vec3 outLight = fragBaseColour * light * max(0.0, dot(fragmentNormal, lightDir)) / (dist * dist);
	float fogFactor = max(0.0, 1.0 - fragDist / fogDist);
	vec3 outLightFogged = mix(skyColour, outLight, fogFactor);
	love_Canvases[0] = vec4(outLightFogged, 1.0);
}

#endif
