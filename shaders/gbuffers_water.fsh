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
in float isWater;
/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outData;

float waveH(vec2 p, float t){
    float h = 0.9 * vnoise(p * 0.35 + vec2(t * 0.20, t * 0.12));
    h += vnoise(p * 0.85 + vec2(t * 0.45, t * 0.30));
    h += 0.55 * vnoise(p * 1.9 + vec2(-t * 0.6, t * 0.35) + 7.3);
    h += 0.30 * vnoise(p * 4.1 + vec2(t * 0.9, t * 0.7) + 3.1);
    return h;
}

void main(){
    vec4 tex = texture(gtexture, texcoord);
    vec3 nV = normalize(normal);
    vec3 nW = normalize(mat3(gbufferModelViewInverse) * nV);
    vec2 lm = clamp((lmcoord - 0.03125) * 1.06667, 0.0, 1.0);
    vec4 res;
    float flag = 0.0;
    if(isWater > 0.5){
        if(nW.y > 0.9){
            float t = frameTimeCounter, e = 0.08;
            vec2 p = worldPos.xz;
            float h0 = waveH(p, t);
            vec2 g = vec2(waveH(p + vec2(e, 0.0), t) - h0, waveH(p + vec2(0.0, e), t) - h0) / e;
            float openSky = IS_SNOW ? 0.0 : smoothstep(0.95, 0.99, lm.y);
            vec2 rg = openSky > 0.0 ? rippleGrad(p) * 0.004 * smoothstep(0.05, 0.4, rainStrength) * openSky : vec2(0.0);
            nW = normalize(vec3(-(g.x * WAVE_STRENGTH + rg.x), 1.0, -(g.y * WAVE_STRENGTH + rg.y)));
            nV = normalize(mat3(gbufferModelView) * nW);
        }
        vec3 albedo = pow(glcolor.rgb, vec3(2.2)) * (0.35 + tex.r * 0.8);
        res = vec4(computeLighting(albedo, lm, nW, viewPos), 0.14);
        flag = 1.0;
    } else {
        vec4 c = tex * glcolor;
        res = vec4(computeLighting(pow(c.rgb, vec3(2.2)), lm, nW, viewPos), c.a);
    }
    outColor = res;
    outNormal = vec4(nV * 0.5 + 0.5, 1.0);
    outData = vec4(lm, flag, 1.0);
}
