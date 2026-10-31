#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uEnabled;

out vec4 fragColor;

void main() {
  vec2 coord = FlutterFragCoord().xy;
  vec2 uv = coord / uResolution;

  if (uEnabled < 0.5) {
    fragColor = vec4(0.0);
    return;
  }

  float scanline = sin(uv.y * 300.0 + uTime * 3.0) * 0.08;
  vec2 centerDist = uv - 0.5;
  float vignette = clamp(1.0 - dot(centerDist, centerDist) * 1.5, 0.0, 1.0);
  vec3 tint = vec3(0.0, 0.9, 0.7);
  float alpha = (0.12 - scanline) * (1.0 - vignette * 0.5);

  fragColor = vec4(tint * alpha, clamp(alpha, 0.0, 0.22));
}
