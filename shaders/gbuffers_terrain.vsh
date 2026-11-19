#version 330 compatibility
#include "/lib/wind.glsl"
in vec4 mc_Entity;
in vec2 mc_midTexCoord;
out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 viewPos;
out vec3 worldPos;
out float foliage;
void main(){
    vec4 v = gl_Vertex;
    vec3 wp = (gbufferModelViewInverse * (gl_ModelViewMatrix * v)).xyz + cameraPosition;
    worldPos = wp;
    float id = mc_Entity.x;
    float top = gl_MultiTexCoord0.y < mc_midTexCoord.y ? 1.0 : 0.0;
    foliage = (id > 10001.5 && id < 10006.5) ? 1.0 : 0.0;
    v.xyz += windOffset(wp, id, windTopWeight(id, top));
    vec4 vp = gl_ModelViewMatrix * v;
    viewPos = vp.xyz;
    gl_Position = gl_ProjectionMatrix * vp;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    normal = gl_NormalMatrix * gl_Normal;
}
