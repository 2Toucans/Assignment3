#version 300 es
#define LIGHT_TYPE_DIRECTIONAL 0
#define LIGHT_TYPE_SPOT 1

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 color;
layout(location = 2) in vec3 normal;
layout(location = 3) in vec2 texCoordIn;
out vec4 v_color;
out vec3 v_position;
out vec3 v_normal;
out vec2 v_texcoord;

uniform mat4 modelViewProjectionMatrix;
uniform bool passThrough;
uniform bool shadeInFrag;

void main()
{
    v_normal = normal;
    v_position = position.xyz;
    v_texcoord = texCoordIn;
    v_color = color;

    gl_Position = position;
}
