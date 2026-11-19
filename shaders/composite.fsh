#version 330 compatibility
/*
const int colortex0Format = RGBA16F;
const int colortex3Format = RGBA16F;
const bool colortex3Clear = false;
*/
#include "/lib/sky.glsl"
#include "/lib/caustics.glsl"
#include "/lib/biomes.glsl"
uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D colortex3;
uniform float frameTime;
in vec2 texcoord;
/* RENDERTARGETS: 0,3 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outHist;
void main(){
    // smoothed "aurora allowed in this biome" value, kept in colortex3 between frames
    float prevA = texture(colortex3, vec2(0.5)).r;
    gAuroraFade = mix(prevA, auroraBiomeOn() ? 1.0 : 0.0, 1.0 - exp(-frameTime * 0.6));
    outHist = vec4(gAuroraFade, 0.0, 0.0, 1.0);
    vec3 col = texture(colortex0, texcoord).rgb;
    float depth = texture(depthtex0, texcoord).r;
    vec3 vp = toView(texcoord, depth);
    vec3 rd = normalize(mat3(gbufferModelViewInverse) * vp);
    float dist = length(vp);
    bool isSky = depth >= 1.0;
    vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);

    if(isEyeInWater == 1){
#ifdef CAUSTICS
        if(!isSky){
            vec3 nW = mat3(gbufferModelViewInverse) * normalFromDepth(depthtex0, texcoord);
            vec3 Pw = (gbufferModelViewInverse * vec4(vp, 1.0)).xyz + cameraPosition;
            // assumes sea-level water when low down, otherwise a surface a little above the camera
            float ys = cameraPosition.y < 63.0 ? 62.9 : floor(cameraPosition.y / 8.0) * 8.0 + 8.0;
            col *= 1.0 + CAUSTIC_STRENGTH * causticsAt(Pw, nW, sunDir, ys);
        }
#endif
        vec3 wf = vec3(0.02, 0.18, 0.24) * (0.15 + 0.85 * smoothstep(-0.2, 0.3, sunDir.y));
        col = mix(col, wf, isSky ? 1.0 : 1.0 - exp(-dist * 0.09));
    } else {
        if(isSky){
            col = skyFull(rd, sunDir);
        } else {
            float fs = far * (0.5 - 0.3 * rainStrength);
            float f = clamp((dist - fs) / (far - fs), 0.0, 1.0);
            vec3 fogCol = skyBase(normalize(vec3(rd.x, 0.02 + max(rd.y, 0.0) * 0.3, rd.z)), sunDir);
            col = mix(col, fogCol, f * f);
        }
#ifdef CLOUDS
        vec4 cl = clouds(cameraPosition, rd, isSky ? 1e6 : dist, sunDir, ign(gl_FragCoord.xy), CLOUD_STEPS);
        col = col * cl.a + cl.rgb;
#endif
    }
    outColor = vec4(col, 1.0);
}
