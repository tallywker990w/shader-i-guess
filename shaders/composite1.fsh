#version 330 compatibility
#include "/lib/sky.glsl"
#include "/lib/caustics.glsl"
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex3;
in vec2 texcoord;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

float ssr(vec3 p0, vec3 dir, out vec2 hitUV){
    hitUV = vec2(0.0);
    float len = 0.4 * (0.8 + 0.4 * ign(gl_FragCoord.xy));
    vec3 p = p0;
    for(int i = 0; i < SSR_STEPS; i++){
        p += dir * len;
        if(p.z > -near) return 0.0;
        vec4 c = gbufferProjection * vec4(p, 1.0);
        vec2 s = c.xy / c.w * 0.5 + 0.5;
        if(s.x < 0.0 || s.x > 1.0 || s.y < 0.0 || s.y > 1.0) return 0.0;
        float d = texture(depthtex0, s).r;
        if(d < 1.0){
            vec3 sv = toView(s, d);
            float diff = sv.z - p.z;
            if(diff > 0.0 && diff < len * 1.6 + 0.25){
                vec3 lo = p - dir * len, hi = p;
                for(int k = 0; k < 4; k++){
                    vec3 mid = (lo + hi) * 0.5;
                    vec4 cm = gbufferProjection * vec4(mid, 1.0);
                    vec2 sm = cm.xy / cm.w * 0.5 + 0.5;
                    vec3 svm = toView(sm, texture(depthtex0, sm).r);
                    if(svm.z - mid.z > 0.0) hi = mid; else lo = mid;
                }
                vec4 ch = gbufferProjection * vec4(hi, 1.0);
                hitUV = ch.xy / ch.w * 0.5 + 0.5;
                vec2 e = abs(hitUV - 0.5) * 2.0;
                return 1.0 - smoothstep(0.75, 1.0, max(e.x, e.y));
            }
        }
        len *= 1.35;
    }
    return 0.0;
}

vec3 reflectionColor(vec3 pV, vec3 rV, vec3 rW, vec3 sunDir, float skyLm){
    vec2 hit;
    float conf = ssr(pV, rV, hit);
    vec3 sky = skyFull(rW, sunDir);
#ifdef CLOUDS
    vec4 cl = clouds(cameraPosition, rW, 1e6, sunDir, ign(gl_FragCoord.xy), 8);
    sky = sky * cl.a + cl.rgb;
#endif
    sky *= mix(0.03, 1.0, smoothstep(0.25, 0.9, skyLm));
    return mix(sky, texture(colortex0, hit).rgb, conf);
}

void main(){
    gAuroraFade = texture(colortex3, vec2(0.5)).r;
    vec2 uv = texcoord;
    vec3 col = texture(colortex0, uv).rgb;
#ifdef WATER_REFLECTIONS
    vec4 data = texture(colortex2, uv);
    float d0 = texture(depthtex0, uv).r;
    bool water = data.b > 0.75 && d0 < 1.0;
    float pud = (data.b > 0.02 && data.b <= 0.75 && d0 < 1.0) ? data.b * 2.0 : 0.0;
    if(isEyeInWater == 0 && (water || pud > 0.0)){
        vec3 nV = normalize(texture(colortex1, uv).xyz * 2.0 - 1.0);
        vec3 pV = toView(uv, d0);
        vec3 vD = normalize(pV);
        vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
        vec3 Ld = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
        float ndv = clamp(dot(-vD, nV), 0.0, 1.0);
        float fres = 0.02 + 0.98 * pow(1.0 - ndv, 5.0);
        float skyVis = smoothstep(0.25, 0.9, data.g);
        float dayL = smoothstep(-0.2, 0.25, sunDir.y);

        if(water){
            float d1 = texture(depthtex1, uv).r;
            float thick = d1 < 1.0 ? max(length(toView(uv, d1)) - length(pV), 0.0) : 48.0;

            // refraction
            vec3 nFlat = normalize(mat3(gbufferModelView) * vec3(0, 1, 0));
            vec2 ruv = uv + (nV - nFlat).xy * 0.06 * clamp(thick * 0.5, 0.0, 1.0);
            if(ruv.x < 0.0 || ruv.x > 1.0 || ruv.y < 0.0 || ruv.y > 1.0
               || texture(colortex2, ruv).b < 0.75 || texture(depthtex1, ruv).r >= 1.0) ruv = uv;
            vec3 under = texture(colortex0, ruv).rgb;

#ifdef CAUSTICS
            float d1r = texture(depthtex1, ruv).r;
            if(d1r < 1.0){
                vec3 P1 = toView(ruv, d1r);
                vec3 nF = mat3(gbufferModelViewInverse) * normalFromDepth(depthtex1, ruv);
                vec3 Pw = (gbufferModelViewInverse * vec4(P1, 1.0)).xyz + cameraPosition;
                float wy = (gbufferModelViewInverse * vec4(pV, 1.0)).y + cameraPosition.y;
                under *= 1.0 + CAUSTIC_STRENGTH * causticsAt(Pw, nF, sunDir, wy);
            }
#endif

            // depth-based absorption + in-scattering
            vec3 absorb = vec3(0.30, 0.075, 0.045) * WATER_ABSORB;
            under = under * exp(-absorb * thick)
                  + vec3(0.015, 0.17, 0.21) * (0.12 + 0.9 * dayL) * mix(0.3, 1.0, skyVis) * (1.0 - exp(-thick * 0.12));

            // shoreline foam
            vec3 wp = (gbufferModelViewInverse * vec4(pV, 1.0)).xyz + cameraPosition;
            float fn = vnoise(wp.xz * 2.5 + vec2(frameTimeCounter * 0.3, 0.0))
                     + 0.5 * vnoise(wp.xz * 6.0 - vec2(0.0, frameTimeCounter * 0.4));
            float foam = smoothstep(0.7, 0.0, thick) * smoothstep(0.35, 0.9, fn * 0.7 + (0.7 - thick) * 0.5);
            under += foam * vec3(0.85, 0.9, 0.95) * (0.12 + 0.88 * dayL) * mix(0.3, 1.0, skyVis);
            col = under;
            fres = clamp(fres, 0.0, 1.0);
        } else {
            fres = pud * clamp(0.06 + fres * 1.2, 0.0, 0.85);
        }

        vec3 rV = reflect(vD, nV);
        vec3 rW = normalize(mat3(gbufferModelViewInverse) * rV);
        vec3 refl = reflectionColor(pV, rV, rW, sunDir, data.g);
        col = mix(col, refl, fres);

        if(water){
            float spec = pow(max(dot(rW, Ld), 0.0), 900.0);
            col += lightColor(sunDir.y) * spec * 4.0 * skyVis * (1.0 - rainStrength);
        }
    }
#endif
    outColor = vec4(col, 1.0);
}
