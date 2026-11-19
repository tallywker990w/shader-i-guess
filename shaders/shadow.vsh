#version 330 compatibility
#include "/lib/wind.glsl"
#include "/lib/distort.glsl"
in vec4 mc_Entity;
in vec2 mc_midTexCoord;
uniform mat4 shadowModelViewInverse;
out vec2 texcoord;
out vec4 glcolor;
void main(){
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    vec4 v = gl_Vertex;
    vec3 wp = (shadowModelViewInverse * (gl_ModelViewMatrix * v)).xyz + cameraPosition;
    float id = mc_Entity.x;
    float top = gl_MultiTexCoord0.y < mc_midTexCoord.y ? 1.0 : 0.0;
    v.xyz += windOffset(wp, id, windTopWeight(id, top));
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * v);
    gl_Position.xyz = distort(gl_Position.xyz);
}
