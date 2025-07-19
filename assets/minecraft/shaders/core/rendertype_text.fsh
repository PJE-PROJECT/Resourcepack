#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;

in float vertexDistance;
in float depthLevel;
in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
	if (color.a < 0.05) {
		discard;
	}
	
	vec3 light = vec3(0.25, 0.25, 0.25);
	vec3 shadow = vec3(0.248, 0.248, 0.248);
	
	if (lessThan(vertexColor.rgb, shadow) == bvec3(true)) {
		discard;
	}
	
    fragColor = color;
}
