#ifndef RAIN_GLSL
#define RAIN_GLSL
#include "/lib/common.glsl"
float rippleLayer(vec2 p){
    vec2 cell = floor(p), f = fract(p);
    float rnd = hash12(cell);
    float tt = fract(frameTimeCounter * 0.9 + rnd);
    vec2 c = 0.25 + 0.5 * vec2(hash12(cell + 7.7), hash12(cell + 19.1));
    float d = length(f - c);
    float x = d - tt * 0.3;
    float env = exp(-x * x * 180.0) * (1.0 - tt) * (1.0 - tt);
    return sin(x * 70.0) * env;
}
float rippleH(vec2 wp){
    return rippleLayer(wp * 1.6) + 0.8 * rippleLayer(wp * 2.2 + 31.7);
}
vec2 rippleGrad(vec2 wp){
    float e = 0.01, h0 = rippleH(wp);
    return vec2(rippleH(wp + vec2(e, 0.0)) - h0, rippleH(wp + vec2(0.0, e)) - h0) / e;
}
#endif
