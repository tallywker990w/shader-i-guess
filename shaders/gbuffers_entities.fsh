#version 330 compatibility
#define ENTITY
#include "/lib/lighting.glsl"
/*
const bool shadowHardwareFiltering = true;
const int shadowMapResolution = 2048;
const float shadowDistance = 96.0;
*/
uniform sampler2D gtexture;
#ifdef ENTITY
uniform vec4 entityColor;
#endif
in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 viewPos;
/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outData;
void main(){
    vec4 tex = texture(gtexture, texcoord);
    if(tex.a < 0.1) discard;
    vec4 c = tex * glcolor;
#ifdef ENTITY
    c.rgb = mix(c.rgb, entityColor.rgb, entityColor.a);
#endif
    vec3 nV = length(normal) > 0.1 ? normalize(normal) : normalize(mat3(gbufferModelView) * vec3(0, 1, 0));
    vec3 nW = normalize(mat3(gbufferModelViewInverse) * nV);
    vec2 lm = clamp((lmcoord - 0.03125) * 1.06667, 0.0, 1.0);
    vec3 lit = computeLighting(pow(c.rgb, vec3(2.2)), lm, nW, viewPos);
    outColor = vec4(lit, c.a);
    outNormal = vec4(nV * 0.5 + 0.5, 1.0);
    outData = vec4(lm, 0.0, 1.0);
}
