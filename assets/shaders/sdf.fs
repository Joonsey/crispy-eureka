#version 330

in vec3 fragPosition;   // Interpolated world position
out vec4 fragColor;

// Uniforms for multiple spheres
#define MAX_SPHERES 10
uniform vec3 sphereCenters[MAX_SPHERES];
uniform float sphereRadii[MAX_SPHERES];
uniform int sphereCount; // Number of active spheres

void main() {
    float minDist = 10000.0; // Large initial value for min distance
    for (int i = 0; i < sphereCount; i++) {
        // Transform the world position into sphere-local space
        vec3 localPos = fragPosition - sphereCenters[i];

        // Compute the SDF value for this sphere
        float dist = length(localPos) - sphereRadii[i];

        // Keep track of the closest sphere
        minDist = min(minDist, dist);
    }

    // Simple shading: map distance to color
    vec3 color = vec3(1.0) - vec3(smoothstep(-0.01, 0.01, minDist));
    fragColor = vec4(color, 1.0);
}

