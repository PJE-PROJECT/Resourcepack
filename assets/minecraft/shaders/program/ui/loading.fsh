#version 150

in vec2 texCoord;

uniform sampler2D ControlSampler;
uniform sampler2D TitlesSampler;
uniform sampler2D LogoSampler;
uniform sampler2D DiffuseSampler;

uniform vec2 OutSize;

out vec4 fragColor;

const float frame_size_y = 1.0 / 4.0;
const float frame_size_y_logo = 1.0 / 9.0;

float remap(float value, float oldMin, float oldMax, float newMin, float newMax) {
    float t = (value - oldMin) / (oldMax - oldMin);
    return smoothstep(newMin, newMax, t);
}

void main() {
    vec2 texCoordRelative = texCoord / OutSize;
    vec3 timeData = floor(texelFetch(ControlSampler, ivec2(0, 4), 0).rgb * 255.0);
    float time = float(timeData.b);

    if (timeData.rg == vec2(250.0, 249.0)) {
        float frame = float(floor(time / 30.0));
        float value = float(mod(time, 30.0));
        float logoframe = float(floor(time / 10.0));

        logoframe = min(logoframe, 8.0);

        vec4 logo = texture(LogoSampler, vec2(texCoordRelative.x, 1.0 - texCoordRelative.y) * vec2(1.0, frame_size_y_logo) + vec2(0.0, frame_size_y_logo * logoframe));
        vec4 frame1 = texture(TitlesSampler, vec2(texCoordRelative.x, 1.0 - texCoordRelative.y) * vec2(1.0, frame_size_y) + vec2(0.0, frame_size_y * frame));
        vec4 frame2 = texture(TitlesSampler, vec2(texCoordRelative.x, 1.0 - texCoordRelative.y) * vec2(1.0, frame_size_y) + vec2(0.0, frame_size_y * (frame + 1.0)));

        vec4 frames;
        if (time < 30) {
            frames = mix(frame1, frame2,remap(value, 0.0, 30.0, 0.0, 1.0));
        } else if (time < 60) {
            frames = mix(frame1, frame2,remap(value, 0.0, 30.0, 0.0, 1.0));
        } else if (time < 91) {
            frames = mix(frame1, frame2,remap(value, 0.0, 30.0, 0.0, 1.0));
        }

        fragColor = vec4(mix(frames.rgb, logo.rgb, logo.a).rgb, 1.0) * 0.8;
    } else {
        fragColor = texture(DiffuseSampler, texCoordRelative);
    }
}