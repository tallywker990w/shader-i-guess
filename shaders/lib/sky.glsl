#ifndef SKY_GLSL
#define SKY_GLSL
#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"

const float SIGMA = 0.045;

vec3 lightColor(float sh){
    vec3 sunC = mix(vec3(1.0, 0.42, 0.14), vec3(1.0, 0.93, 0.80), smoothstep(0.0, 0.4, sh)) * 3.0;
    float dayM = smoothstep(-0.06, 0.06, sh);
    vec3 moonC = vec3(0.30, 0.42, 0.85) * 0.32;
    return mix(moonC, sunC, dayM);
}

vec3 skyBase(vec3 rd, vec3 sunDir){
    float sh = sunDir.y;
    float day = smoothstep(-0.14, 0.18, sh);
    float dusk = exp(-abs(sh) * 6.0);
    vec3 zen = mix(vec3(0.010, 0.018, 0.050), vec3(0.09, 0.26, 0.68), day);
    vec3 hor = mix(vec3(0.030, 0.040, 0.090), vec3(0.50, 0.68, 0.92), day);
    float sunAz = max(dot(normalize(rd.xz + 1e-4), normalize(sunDir.xz + 1e-4)), 0.0);
    float tint = clamp(dusk * (0.25 + 0.75 * sunAz * sunAz), 0.0, 1.0);
    hor = mix(hor, vec3(1.0, 0.42, 0.16), tint * 0.8);
    float t = pow(1.0 - clamp(rd.y, 0.0, 1.0), 3.0);
    vec3 col = mix(zen, hor, t);
    float g = dot(col, vec3(0.333));
    return mix(col, vec3(g) * 0.75, rainStrength * 0.85);
}

// ---------- volumetric clouds ----------
float fbm3(vec2 p){
    float a = 0.5, s = 0.0;
    for(int i = 0; i < 3; i++){ s += a * vnoise(p); p = p * 2.03 + vec2(17.1, 9.2); a *= 0.5; }
    return s / 0.875;
}
float fbm2(vec2 p){
    return (0.5 * vnoise(p) + 0.25 * vnoise(p * 2.03 + vec2(17.1, 9.2))) / 0.75;
}


// ---------- night sky: milky way ----------
float gAuroraFade = 0.0;   // 0..1, smoothed "this biome has aurora" value (set in main)

float starLayer(vec3 r, float S, float thresh, float seed){
    vec3 p = r * S;
    vec3 c = floor(p);
    vec3 f = fract(p) - 0.5;
    float h = hash13(c + seed);
    if(h < thresh) return 0.0;
    vec3 j = (vec3(hash13(c + seed + 3.1), hash13(c + seed + 7.3), hash13(c + seed + 9.7)) - 0.5) * 0.5;
    float b = (h - thresh) / (1.0 - thresh);
    return smoothstep(0.30, 0.0, length(f - j)) * (0.25 + b * b * 2.2);
}

vec3 nightSky(vec3 rd, vec3 sunDir){
    // sky turns with the sun
    vec2 sc = normalize(sunDir.xy + 1e-5);
    vec3 r = vec3(sc.x * rd.x + sc.y * rd.y, -sc.y * rd.x + sc.x * rd.y, rd.z);

    vec3 g  = normalize(vec3(0.15, 0.70, 0.70));          // galactic pole
    vec3 e1 = normalize(vec3(g.y, -g.x, 0.0));            // along the band
    vec3 e2 = cross(g, e1);
    float b = dot(r, g), u = dot(r, e1), v = dot(r, e2);

    float band = exp(-b * b * 9.0);
    vec2 np = vec2(u, v) * 5.0 + vec2(b * 9.0, -b * 7.0);
    float d1 = fbm3(np);
    float d2 = fbm3(np * 2.3 + 11.0);
    float dust = smoothstep(0.45, 0.75, d1) * smoothstep(0.35, 0.70, d2);
    float core = band * band * smoothstep(-0.2, 0.9, -u);

    vec3 col = vec3(0.075, 0.085, 0.20) * band * (0.35 + 0.9 * d2) * 1.3;       // blue-violet haze
    col += vec3(0.32, 0.22, 0.15) * core * (0.4 + d1) * 1.1;                     // warm core
    col *= 1.0 - 0.85 * dust * band;                                             // dark dust lanes

    // stars: far more of them inside the band
    float s1 = starLayer(r, 520.0,  1.0 - (0.012 + 0.05 * band), 0.0);
    float s2 = starLayer(r, 1050.0, 1.0 - (0.030 + 0.12 * band), 41.0);
    float tint = hash13(floor(r * 520.0) + 5.5);
    vec3 starCol = mix(vec3(1.0, 0.80, 0.65), vec3(0.70, 0.82, 1.0), tint);
    col += starCol * (s1 * 1.6 + s2 * 0.7) * (1.0 - 0.7 * dust * band);

    // one bright planet low in the sky
    float cp = dot(normalize(r), normalize(vec3(-0.55, 0.25, 0.80)));
    col += vec3(1.0, 0.95, 0.9) * (smoothstep(0.99992, 0.99998, cp) * 5.0 + pow(max(cp, 0.0), 900.0) * 0.5);
    return col;
}

// ---------- aurora ----------
vec3 auroraPalette(float h){
#if AURORA_COLOR == 0
    return mix(vec3(0.10, 1.00, 0.35), vec3(0.15, 0.85, 0.65), h);
#elif AURORA_COLOR == 1
    vec3 c = mix(vec3(0.10, 1.00, 0.35), vec3(0.55, 0.20, 1.00), smoothstep(0.30, 1.0, h));
    return mix(c, vec3(1.0, 0.25, 0.55), smoothstep(0.85, 1.0, h) * 0.5);
#elif AURORA_COLOR == 2
    return mix(vec3(0.10, 0.90, 1.00), vec3(0.20, 0.30, 1.00), h);
#else
    return mix(vec3(1.00, 0.30, 0.65), vec3(0.45, 0.25, 1.00), h);
#endif
}

vec3 aurora(vec3 rd){
    if(rd.y < 0.015) return vec3(0.0);
    float tm = frameTimeCounter * AURORA_SPEED;
    float dither = ign(gl_FragCoord.xy);
    float elev = smoothstep(0.015, 0.25, rd.y) * (1.0 - 0.5 * smoothstep(0.7, 1.0, rd.y));
    // big patches so it doesn't blanket the whole sky
    float mask = 0.2 + 0.8 * smoothstep(0.30, 0.70, fbm2(rd.xz / (rd.y + 0.4) * 0.9 + vec2(tm * 0.01, 3.7)));
    vec3 acc = vec3(0.0);
    for(int i = 0; i < AURORA_STEPS; i++){
        float h = (float(i) + dither) / float(AURORA_STEPS);
        float py = mix(250.0, 700.0, h);
        vec2 p = rd.xz * (py / (rd.y + 0.1)) * 0.0018;      // different heights shift = volumetric look
        vec2 q = p + vec2(tm * 0.03, 0.0);
        float warp = fbm2(q * 0.7 + vec2(0.0, tm * 0.02));
        float ridge = abs(vnoise(vec2(q.x * 0.9 + warp * 3.5, q.y * 0.35 + h * 0.4)) - 0.5);
        float curtain = smoothstep(0.10, 0.0, ridge);
        float rays = 0.55 + 0.45 * vnoise(vec2(q.x * 9.0 + tm * 0.4, q.y * 1.5));
        float vf = smoothstep(0.0, 0.12, h) * (1.0 - smoothstep(0.55, 1.0, h) * 0.6);
        acc += auroraPalette(h) * curtain * rays * vf * (1.0 - 0.4 * h);
    }
    return acc * (3.0 / float(AURORA_STEPS)) * elev * mask * AURORA_BRIGHTNESS;
}

vec3 skyFull(vec3 rd, vec3 sunDir){
    vec3 col = skyBase(rd, sunDir);
    float day = smoothstep(-0.1, 0.1, sunDir.y);
    float horizon = smoothstep(-0.05, 0.02, rd.y);
    float cs = dot(rd, sunDir);
    col += vec3(1.0, 0.72, 0.42) * pow(max(cs, 0.0), 20.0) * 0.35 * (1.0 - rainStrength);
    col += vec3(1.0, 0.92, 0.75) * smoothstep(0.9993, 0.9997, cs) * 60.0 * horizon * (1.0 - rainStrength);
    float cm = dot(rd, -sunDir);
    col += vec3(0.75, 0.85, 1.0) * smoothstep(0.9994, 0.9997, cm) * 6.0 * horizon * (1.0 - day) * (1.0 - rainStrength);
    float night = 1.0 - smoothstep(-0.2, 0.05, sunDir.y);
    float clear = 1.0 - rainStrength;
    float above = smoothstep(-0.02, 0.12, rd.y);
#ifdef GALAXY
    if(night > 0.01) col += nightSky(rd, sunDir) * night * clear * above * GALAXY_BRIGHTNESS;
#endif
#ifdef AURORA
    float an = night, boost = 1.0;
#ifdef AURORA_ALWAYS_VISIBLE
    an = 1.0;
    boost = 1.0 + 3.0 * (1.0 - night);
#endif
    float amt = an * gAuroraFade * clear;
    if(amt > 0.01) col += aurora(rd) * amt * boost;
#endif
    return col;
}

vec3 ambientSky(vec3 n, vec3 sunDir){
    vec3 up = skyBase(vec3(0,1,0), sunDir);
    vec3 hz = skyBase(normalize(vec3(n.x, 0.05, n.z)), sunDir);
    return mix(hz, up, clamp(n.y * 0.5 + 0.5, 0.0, 1.0)) * 0.9;
}

float cloudDensity(vec3 p, float h, bool hi){
    vec2 wind = vec2(1.0, 0.35) * frameTimeCounter * CLOUD_SPEED;
    vec2 uv = (p.xz + wind) * 0.0011;
    float n = hi ? fbm3(uv) : fbm2(uv);
    float cov = clamp(CLOUD_COVERAGE + rainStrength * 0.25, 0.0, 1.0);
    float thr = 0.70 - 0.40 * cov;
    float core = clamp((n - thr) * 3.0, 0.0, 1.0);
    float topH = 0.35 + 0.65 * core;
    float prof = smoothstep(0.0, 0.1, h) * (1.0 - smoothstep(topH * 0.6, topH, h));
    float detail = hi ? vnoise(p.xz * 0.012 + vec2(p.y * 0.045, -p.y * 0.03) + wind * 0.02) : 0.5;
    float d = clamp((n - thr - (detail - 0.5) * 0.22) * 3.5, 0.0, 1.0);
    return d * prof;
}

float hg(float c, float g){
    float g2 = g * g;
    return (1.0 - g2) / pow(1.0 + g2 - 2.0 * g * c, 1.5) * 0.25;
}

// returns (scattered radiance, transmittance)
vec4 clouds(vec3 ro, vec3 rd, float maxDist, vec3 sunDir, float dither, int steps){
    float base = float(CLOUD_HEIGHT), thick = float(CLOUD_THICKNESS), top = base + thick;
    if(abs(rd.y) < 1e-3) return vec4(0, 0, 0, 1);
    float t0 = (base - ro.y) / rd.y, t1 = (top - ro.y) / rd.y;
    float tn = max(min(t0, t1), 0.0), tf = min(max(t0, t1), maxDist);
    if(tf <= tn || tn > 7000.0) return vec4(0, 0, 0, 1);
    tf = min(tf, tn + 1800.0);

    float dt = (tf - tn) / float(steps);
    float t = tn + dt * dither;
    vec3 L = sunDir.y > -0.12 ? sunDir : -sunDir;
    vec3 lc = lightColor(sunDir.y) * (1.0 - 0.5 * rainStrength);
    vec3 amb = skyBase(vec3(0, 1, 0), sunDir) * 0.9 + 0.05;
    float cosT = dot(rd, L);
    float phase = mix(hg(cosT, -0.25), hg(cosT, 0.7), 0.5);

    vec3 acc = vec3(0.0);
    float trans = 1.0;
    for(int i = 0; i < steps; i++){
        vec3 p = ro + rd * t;
        float h = (p.y - base) / thick;
        float d = cloudDensity(p, h, true);
        if(d > 0.003){
            float ls = thick * 0.22, od = 0.0;
            for(int j = 1; j <= 3; j++){
                vec3 lp = p + L * ls * float(j);
                float lh = (lp.y - base) / thick;
                if(lh < 0.0 || lh > 1.0) break;
                od += cloudDensity(lp, lh, false);
            }
            od *= ls * SIGMA;
            float tl = exp(-od) + 0.35 * exp(-od * 0.25);
            vec3 S = lc * tl * phase + amb * mix(0.45, 1.0, clamp(h, 0.0, 1.0));
            float st = exp(-d * SIGMA * dt);
            acc += trans * (1.0 - st) * S;
            trans *= st;
            if(trans < 0.02) break;
        }
        t += dt;
    }
    float fade = exp(-tn * 0.00045);
    return vec4(acc * fade, mix(1.0, trans, fade));
}
#endif
