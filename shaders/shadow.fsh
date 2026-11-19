#version 330 compatibility
/*
const bool shadowHardwareFiltering = true;
const int shadowMapResolution = 2048;
const float shadowDistance = 96.0;
*/
uniform sampler2D gtexture;
in vec2 texcoord;
in vec4 glcolor;
layout(location = 0) out vec4 outColor;
void main(){
    vec4 c = texture(gtexture, texcoord) * glcolor;
    if(c.a < 0.1) discard;
    outColor = c;
}
