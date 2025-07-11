#version 150

uniform sampler2D DiffuseSampler;
uniform sampler2D ControlSampler;
uniform sampler2D DepthSampler;
uniform sampler2D TranslucentSampler;

in vec2 texCoord;
flat in int hasReflections;
flat in mat4 projMat;
flat in mat4 invProjMat;
flat in vec3 worldPosition;
flat in float gameTime;
flat in mat3 tbnMatrix;

out vec4 fragColor;

////////////////////////////////////////////////////////////

// from https://github.com/stegu/webgl-noise/blob/master/src/noise2D.glsl
vec3 permute(vec3 x) {
    return mod(((x * 34.0) + 1.0) * x, 289.0);
}

float snoise(vec2 v){
    const vec4 C = vec4(
        0.211324865405187,
        0.366025403784439,
        -0.577350269189626,
        0.024390243902439
    );
    
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v -  i + dot(i, C.xx);

    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = mod(i, 289.0);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = (m * m) * (m * m);

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
  
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// based on https://www.shadertoy.com/view/MdXyzX
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
    float x = dot(direction, position) * frequency + timeshift;
    float wave = exp(sin(x) - 1.0);
    float dx = wave * cos(x);
    return vec2(wave, -dx);
}

float wave(vec2 position, float time) {
    float wavePhaseShift = length(position) * 0.1;

    float frequency = 1.0;
    float timeMultiplier = 2.0;
    float weight = 1.0;
    
    float value = 0.0;
    float totalWeight = 0.0;
    
    for(int i = 0; i < 6; i++) {
        vec2 p = vec2(sin(i * 1232.399963), cos(i * 1232.399963));
        vec2 res = wavedx(position, p, frequency, time + wavePhaseShift);
        position += p * res.y * weight * 0.38;
        
        value += res.x * weight;
        totalWeight += weight;
        
        weight *= 0.8;
        frequency *= 1.18;
        timeMultiplier *= 1.07;
    }

    value += snoise(position * 0.2);
    value += snoise(position * 0.1) * 2.0;
    totalWeight += 3.0;
  
    return (value / totalWeight) * 0.15;
}

vec3 waveNormal(vec2 pos, float time) {
    pos *= vec2(6.0, 8.0);

    vec2 e = vec2(0.01, 0);
    float h = wave(pos, time);

    return normalize(cross(
        vec3(pos.x, h, pos.y) - vec3(pos.x - e.x, wave(pos - e.xy, time), pos.y),
        vec3(pos.x, h, pos.y) - vec3(pos.x, wave(pos + e.yx, time), pos.y + e.x)
    ));
}

////////////////////////////////////////////////////////////

vec3 project(mat4 projection, vec3 position) {
	vec4 h = projection * vec4(position, 1.0);
	return h.xyz / h.w;
}

float fresnelRs(float n0, float cos0, float n1, float cos1) {
    return (n0 * cos0 - n1 * cos1) / (n0 * cos0 + n1 * cos1);
}

float fresnelRp(float n0, float cos0, float n1, float cos1) {
    return (n0 * cos1 - n1 * cos0) / (n0 * cos1 + n1 * cos0);
}

float fresnelDielectric(float cosTheta0, float n0, float n1) {
    float sin2Theta0 = 1.0 - cosTheta0 * cosTheta0;
    float sin2Theta1 = sin2Theta0 * (n0 * n0) / (n1 * n1);
    if (sin2Theta1 >= 1.0) return 1.0;

    float cosTheta1 = sqrt(1.0 - sin2Theta1);

    float rs = fresnelRs(n0, cosTheta0, n1, cosTheta1);
    float rp = fresnelRp(n0, cosTheta0, n1, cosTheta1);

    return 0.5 * (rs * rs + rp * rp);
}

float linearizeDepth(float depth) {
	return -1.0 / (invProjMat[2][3] * depth + invProjMat[3][3]);
}

vec2 binaryRefinement(vec3 position, vec3 direction, float t0, float t1) {
	vec3 projected;
	for (int i = 0; i < 3; i++) {
        float t = (t0 + t1) * 0.5;
        vec3 viewPos = position + direction * t;

        projected = project(projMat, viewPos) * 0.5 + 0.5;
		
		float depth = texture(DepthSampler, projected.xy).r;
        if (depth < projected.z) {
            t1 = t;
        } else {
            t0 = t;
        }
    }

	return projected.xy;
}

vec2 raytrace(vec3 position, vec3 direction, float cosTheta) {
	float tStep = 0.05 / max(0.001, cosTheta);
	float t0 = 0.0, t = 0.0;

	for (int i = 0; i < 32; i++) {
		t += tStep;
		tStep *= 1.15;

		vec3 viewPos = position + direction * t;
		vec3 screenPos = project(projMat, viewPos) * 0.5 + 0.5;
		if (clamp(screenPos, 0.0, 1.0) != screenPos) {
			break;
		}

		float depth = texture(DepthSampler, screenPos.xy).r;
		depth = linearizeDepth(depth * 2.0 - 1.0);
		if (viewPos.z < depth && viewPos.z > depth - tStep * 1.5) {
			return binaryRefinement(position, direction, t0, t);
		}

		t0 = t;
	}

	return vec2(-1.0);
}

void main() {
	fragColor = texture(DiffuseSampler, texCoord);
	if (hasReflections == 0 || texture(TranslucentSampler, texCoord).rgb == vec3(0.0) || texture(ControlSampler, texCoord).rgb != vec3(0.0)) {
		return;
	}

	float depth = texture(DepthSampler, texCoord).r;
	vec3 fragPos = project(invProjMat, vec3(texCoord, depth) * 2.0 - 1.0);
	vec3 viewDir = normalize(fragPos);
	
	vec3 waterNormal = tbnMatrix * waveNormal((fragPos * tbnMatrix).xz - worldPosition.xz, gameTime * 2500.0);

	float cosTheta = clamp(dot(-viewDir, waterNormal), 0.0, 1.0);
	float reflectance = fresnelDielectric(cosTheta, 1.0, 3);

	vec3 reflectedDir = reflect(viewDir, waterNormal);
	reflectedDir.y = abs(reflectedDir.y);

	vec2 ssrCoord = raytrace(fragPos, reflectedDir, cosTheta);
	if (ssrCoord.x < 0.0) {
		return;
	}

	vec3 ssrColor = texture(DiffuseSampler, ssrCoord).rgb;

	fragColor.rgb = mix(fragColor.rgb, ssrColor, reflectance);
}