#ifndef UNIFORMS_GLSL
#define UNIFORMS_GLSL
#include "/lib/settings.glsl"
uniform mat4 gbufferModelView, gbufferModelViewInverse, gbufferProjection, gbufferProjectionInverse;
uniform vec3 cameraPosition, sunPosition, shadowLightPosition;
uniform float frameTimeCounter, rainStrength, wetness, near, far, viewWidth, viewHeight;
uniform int isEyeInWater;
uniform int biome_precipitation; // 0 none, 1 rain, 2 snow
#define IS_SNOW (biome_precipitation == 2)
#endif
