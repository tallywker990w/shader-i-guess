#version 330 compatibility
#include "/lib/lighting.glsl"
#include "/lib/rain.glsl"
/*
const bool shadowHardwareFiltering = true;
const int shadowMapResolution = 2048;
const float shadowDistance = 96.0;
*/
uniform sampler2D gtexture;
in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 viewPos;
in vec3 worldPos;
in float foliage;
/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outData;
void main(){
    vec4 tex = texture(gtexture, texcoord);
    if(tex.a < 0.1) discard;
    vec4 c = tex * glcolor;
    vec3 nV = length(normal) > 0.1 ? normalize(normal) : normalize(mat3(gbufferModelView) * vec3(0, 1, 0));
    vec3 nW = normalize(mat3(gbufferModelViewInverse) * nV);
    vec2 lm = clamp((lmcoord - 0.03125) * 1.06667, 0.0, 1.0);
    vec3 albedo = pow(c.rgb, vec3(2.2));
    float pud = 0.0;
#ifdef RAIN_PUDDLES
    if(wetness > 0.01 && foliage < 0.5 && !IS_SNOW){
        float sky = smoothstep(0.95, 0.99, lm.y); // only fully sky-exposed surfaces get wet
        albedo *= mix(1.0, 0.6, wetness * sky);
        float up = smoothstep(0.85, 0.98, nW.y);
        float n = vnoise(worldPos.xz * 0.25) * 0.65 + vnoise(worldPos.xz * 0.9 + 13.7) * 0.35;
        float thr = mix(0.28, 0.46, wetness);
        pud = (1.0 - smoothstep(thr - 0.07, thr, n)) * up * sky;
        albedo *= mix(1.0, 0.55, pud);
        if(pud > 0.04){
            vec2 g = rippleGrad(worldPos.xz) * 0.005 * smoothstep(0.05, 0.4, rainStrength);
            nW = normalize(vec3(-g.x, 1.0, -g.y));
            nV = normalize(mat3(gbufferModelView) * nW);
        }
    }
#endif
    outColor = vec4(computeLighting(albedo, lm, nW, viewPos), c.a);
    outNormal = vec4(nV * 0.5 + 0.5, 1.0);
    outData = vec4(lm, pud * 0.5, 1.0);
}
