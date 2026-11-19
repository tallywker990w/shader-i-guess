#version 330 compatibility
#include "/lib/settings.glsl"
uniform sampler2D colortex0;
in vec2 texcoord;
layout(location = 0) out vec4 outColor;
vec3 aces(vec3 x){
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}
void main(){
    vec3 c = texture(colortex0, texcoord).rgb * EXPOSURE * 0.8;
    c = aces(c);
    c = pow(c, vec3(1.0 / 2.2));
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    c = mix(vec3(l), c, SATURATION);
    outColor = vec4(c, 1.0);
}
