#version 150

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;

in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;


vec3 sat(vec3 rgb, float intensity) {  
    vec3 L = vec3(0.2125, 0.7154, 0.0721);  
    vec3 grayscale = vec3(dot(rgb, L));  
    return mix(grayscale, rgb, intensity);  
}


void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a == 0.0) {
        discard;
    }
    vec3 color2 = sat(vertexColor.rgb*color.rgb, 1.8)*1.2;
    fragColor =  vec4(ColorModulator.rgb * color2, ColorModulator.a * color.a *1.3);

}