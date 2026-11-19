#ifndef CAUSTICS_GLSL
#define CAUSTICS_GLSL
#include "/lib/common.glsl"

// seamless animated caustic web (tile = 1 uv unit)
float causticPattern(vec2 uv, float time){
    vec2 p = mod(uv * 6.28318, 6.28318) - 250.0;
    vec2 i = p;
    float c = 1.0;
    const float inten = 0.005;
    for(int n = 0; n < 4; n++){
        float t = time * (1.0 - (3.5 / float(n + 1)));
        i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0 / length(vec2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
    }
    c /= 4.0;
    c = 1.17 - pow(c, 1.4);
    return pow(abs(c), 8.0);
}

// view-space surface normal rebuilt from the depth buffer
vec3 normalFromDepth(sampler2D dt, vec2 uv){
    vec2 px = 1.0 / vec2(viewWidth, viewHeight);
    vec3 p0 = toView(uv, texture(dt, uv).r);
    vec2 ur = uv + vec2(px.x, 0.0), ul = uv - vec2(px.x, 0.0);
    vec2 uu = uv + vec2(0.0, px.y), ud = uv - vec2(0.0, px.y);
    vec3 pr = toView(ur, texture(dt, ur).r), pl = toView(ul, texture(dt, ul).r);
    vec3 pu = toView(uu, texture(dt, uu).r), pd = toView(ud, texture(dt, ud).r);
    vec3 dx = abs(pr.z - p0.z) < abs(p0.z - pl.z) ? pr - p0 : p0 - pl;
    vec3 dy = abs(pu.z - p0.z) < abs(p0.z - pd.z) ? pu - p0 : p0 - pd;
    vec3 n = normalize(cross(dx, dy));
    if(dot(n, p0) > 0.0) n = -n;
    return n;
}

// P: world position of the lit surface, nW: its world normal, sunDir: world dir to the sun, waterY: water surface height
float causticsAt(vec3 P, vec3 nW, vec3 sunDir, float waterY){
    float h = waterY - P.y;
    if(h < 0.0 || sunDir.y < 0.02) return 0.0;
    // light bends toward vertical when entering water
    vec3 Lr = normalize(vec3(sunDir.x / 1.33, max(sunDir.y, 0.05), sunDir.z / 1.33));
    // follow the light ray from the surface down to the point: where did it cross the water plane?
    vec2 q = (P + Lr * (h / Lr.y)).xz;
    float c = causticPattern(q * 0.18, frameTimeCounter * 0.5 + 23.0);
    float facing = clamp(dot(nW, Lr), 0.0, 1.0);       // noon: floors only. low sun: walls facing the sun too
    float depthFade = exp(-h * 0.12);
    float daylight = smoothstep(0.02, 0.3, sunDir.y);
    return c * facing * depthFade * daylight * (1.0 - 0.85 * rainStrength);
}
#endif
