#version 330

in vec2 fragTexCoord;

// my scene texture
uniform sampler2D texture0;

// my lights
uniform sampler2D lighting;

// my occlusion mask
uniform sampler2D occlusion;

uniform int rayCount = 8;
uniform int maxSteps = 264;
uniform vec2 size;


const float PI = 3.14159265;
const float TAU = 2.0 * PI;

bool outOfBounds(vec2 uv) {
	return uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0;
}

float rand(vec2 co) {
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec4 raymarch() {
	vec2 vUv = fragTexCoord;
	vec4 light = texture(lighting, vUv);
	float oneOverRayCount = 1.0 / float(rayCount);
	float tauOverRayCount = TAU * oneOverRayCount;

	// Distinct random value for every pixel
	float noise = rand(vUv);

	vec4 radiance = vec4(0.0);

	if (light.a > 0.1) {
		return light;
	}

	for(int i = 0; i < rayCount; i++) {
		float angle = tauOverRayCount * (float(i) + noise);
		vec2 rayDirectionUv = vec2(cos(angle), -sin(angle)) / size;

		// Our current position, plus one step.
		vec2 sampleUv = vUv + rayDirectionUv;

		for (int step = 0; step < maxSteps; step++) {
			if (outOfBounds(sampleUv)) break;

			vec4 sampleLight = texture(lighting, sampleUv);
			if (sampleLight.a > 0.1) {
				radiance += sampleLight;
				break;
			}

			vec4 sampleOcclusion = texture(occlusion, sampleUv);
			if (sampleOcclusion.a > 0.1) {
				break;
			}

			sampleUv += rayDirectionUv;
		}
	}
	return radiance * oneOverRayCount;
}

void main() {
	vec4 light = raymarch();
	vec4 scene = texture(texture0, fragTexCoord);
	scene *= .5;
	gl_FragColor = vec4(scene.rgb + light.rgb, 1);
}

