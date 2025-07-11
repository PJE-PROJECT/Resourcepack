#version 150

#define X 0
#define Y 1
#define Z 2

#define PI 3.14159265

//matrix 4

mat4 MakeMat4() {
	return mat4(1.0, 0.0, 0.0, 0.0,
				0.0, 1.0, 0.0, 0.0,
				0.0, 0.0, 1.0, 0.0,
				0.0, 0.0, 0.0, 1.0);
}

mat4 Rotate(float angle, int type) {
	float s1n = sin(angle);
	float c0s = cos(angle);

	if (type == 0) {
		return mat4(1.0, 0.0,  0.0, 0.0,
					0.0, c0s, -s1n, 0.0,
					0.0, s1n,  c0s, 0.0,
					0.0, 0.0,  0.0, 1.0);
	}
	if (type == 1) {
		return mat4( c0s, 0.0, s1n, 0.0,
					 0.0, 1.0, 0.0, 0.0,
					-s1n, 0.0, c0s, 0.0,
					 0.0, 0.0, 0.0, 1.0);
	}
	if (type == 2) {
		return mat4(c0s, -s1n, 0.0, 0.0,
					s1n,  c0s, 0.0, 0.0,
					0.0,  0.0, 1.0, 0.0,
					0.0,  0.0, 0.0, 1.0);
	}			

	return mat4(0.0);
}

mat3 Rotate3(float angle, int type) {
	float s1n = sin(angle);
	float c0s = cos(angle);

	if (type == 0) {
		return mat3(1.0, 0.0, 0.0,
					0.0, c0s, -s1n,
					0.0, s1n,  c0s);
	}
	if (type == 1) {
		return mat3( c0s, 0.0, s1n,
					 0.0, 1.0, 0.0,
					-s1n, 0.0, c0s);
	}
	if (type == 2) {
		return mat3(c0s, -s1n, 0.0,
					s1n,  c0s, 0.0,
					0.0,  0.0, 1.0);
	}			

	return mat3(0.0);
}