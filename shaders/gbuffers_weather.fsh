#version 330 compatibility
#include "/lib/sky.glsl"
uniform sampler2D gtexture;
in vec2 texcoord;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;
void main(){
    vec4 t = texture(gtexture, texcoord);
    if(t.a < 0.02) discard;
    vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 c = ambientSky(vec3(0, 1, 0), sunDir) * 1.6 + 0.03;
    outColor = vec4(c * (0.8 + 0.2 * t.r), t.a * 0.45);
}
