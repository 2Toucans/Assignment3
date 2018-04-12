#version 300 es

#define LIGHT_TYPE_DIRECTIONAL 0
#define LIGHT_TYPE_SPOT 1
#define LIGHT_TYPE_AMBIENT 2

precision highp float;
in vec4 v_color;
in vec3 v_position;
in vec3 v_normal;
in vec2 v_texcoord;
out vec4 o_fragColor;

uniform mat4 modelViewProjectionMatrix;
uniform bool passThrough;
uniform bool shadeInFrag;

void main()
{
    o_fragColor = v_color;
}

