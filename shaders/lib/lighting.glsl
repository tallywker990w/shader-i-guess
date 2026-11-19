#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"
#include "/lib/sky.glsl"
#include "/lib/distort.glsl"

uniform sampler2DShadow shadowtex1;
uniform mat4 shadowModelView, shadowProjection;

float getShadow(vec3 feet, vec3 nW){
    vec4 sp = shadowProjection * (shadowModelView * vec4(feet, 1.0));
    float len = length(sp.xy);
    vec3 off = nW * (0.03 + 0.10 * clamp(len, 0.0, 1.2));
    sp = shadowProjection * (shadowModelView * vec4(feet + off, 1.0));
    sp.xyz = distort(sp.xyz) * 0.5 + 0.5;
    sp.z -= 0.0003;
    float edge = max(abs(sp.x - 0.5), abs(sp.y - 0.5)) * 2.0;
    if(edge >= 1.0 || sp.z >= 1.0) return 1.0;
    float a = ign(gl_FragCoord.xy) * 6.2831853;
    vec2 r = vec2(cos(a), sin(a)) * (1.4 / 2048.0);
    vec2 q = vec2(-r.y, r.x);
    float s = texture(shadowtex1, vec3(sp.xy + r, sp.z))
            + texture(shadowtex1, vec3(sp.xy - r, sp.z))
            + texture(shadowtex1, vec3(sp.xy + q, sp.z))
            + texture(shadowtex1, vec3(sp.xy - q, sp.z));
    return mix(s * 0.25, 1.0, smoothstep(0.8, 1.0, edge));
}

vec3 computeLighting(vec3 albedo, vec2 lm, vec3 nW, vec3 viewPos){
    vec3 feet = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 L = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float ndl = dot(nW, L);
    float sh = 1.0;
    if(ndl > 0.0 && lm.y > 0.2) sh = getShadow(feet, nW);
    float direct = max(ndl, 0.0) * sh * smoothstep(0.2, 0.85, lm.y) * (1.0 - 0.9 * rainStrength);
    float day = smoothstep(-0.14, 0.18, sunDir.y);
    vec3 amb = ambientSky(nW, sunDir) * lm.y * lm.y;
    amb += (1.0 - day) * vec3(0.02, 0.03, 0.06) * lm.y * lm.y;
    vec3 torch = vec3(1.0, 0.52, 0.22) * pow(lm.x, 4.0) * 2.0;
    return albedo * (lightColor(sunDir.y) * direct + amb + torch + 0.01);
}
