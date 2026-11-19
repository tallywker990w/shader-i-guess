#ifndef WIND_GLSL
#define WIND_GLSL
#include "/lib/common.glsl"
// world-space displacement. id: 10002 leaves, 10003-10005 plants (topW = bend weight), 10006 cane
vec3 windOffset(vec3 wp, float id, float topW){
#ifdef WAVING_FOLIAGE
    if(id < 10001.5 || id > 10006.5) return vec3(0.0);
    float t = frameTimeCounter;
    float gust = 0.6 + 0.4 * vnoise(wp.xz * 0.05 + t * vec2(0.15, 0.10));
    float strength = (1.0 + rainStrength * 1.2) * WIND_STRENGTH * gust;
    vec2 dir = vec2(0.8, 0.6);
    float ph = dot(wp.xz, dir) * 0.6 - t * 2.0;
    vec2 w = dir * (sin(ph) * 0.5 + 0.35) + vec2(-dir.y, dir.x) * sin(ph * 1.7 + wp.y) * 0.15;
    float fl = vnoise(wp.xz * 1.3 + wp.y * 0.7 + vec2(t * 2.0, -t * 1.7)) - 0.5;
    float fl2 = vnoise(wp.zx * 1.1 + wp.y * 0.5 + vec2(-t * 1.6, t * 2.1)) - 0.5;
    if(id < 10002.5){            // leaves (continuous in world space, so blocks never tear apart)
        return vec3(w.x * 0.05 + fl * 0.07, fl * 0.04, w.y * 0.05 + fl2 * 0.07) * strength;
    } else if(id < 10005.5){     // plants
        vec3 o = vec3(w.x, 0.0, w.y) * 0.16 + vec3(fl, 0.0, fl2) * 0.06;
        o.y = -(abs(w.x) + abs(w.y)) * 0.05;
        return o * strength * topW;
    } else {                     // sugar cane / bamboo
        return vec3(w.x, 0.0, w.y) * 0.07 * strength * (0.6 + 0.4 * sin(wp.y * 0.8 + t * 0.9));
    }
#else
    return vec3(0.0);
#endif
}
float windTopWeight(float id, float top){
    if(abs(id - 10003.0) < 0.5) return top;
    if(abs(id - 10004.0) < 0.5) return 0.5 * top;
    if(abs(id - 10005.0) < 0.5) return 0.5 + 0.5 * top;
    return 0.0;
}
#endif
