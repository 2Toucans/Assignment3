#version 300 es

#define LIGHT_TYPE_DIRECTIONAL 0
#define LIGHT_TYPE_SPOT 1
#define LIGHT_TYPE_AMBIENT 2

precision highp float;
in vec4 v_color;
in vec3 v_position;
in vec3 v_localPosition;
in vec3 v_normal;
in vec2 v_texcoord;
out vec4 o_fragColor;

struct Light {
    int type;
    vec3 color;
    vec3 position;
    vec3 direction;
    float size;
};


uniform sampler2D texSampler;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 modelMatrix;
uniform mat3 normalMatrix;
uniform bool passThrough;
uniform bool shadeInFrag;
uniform Light lights[10];
uniform int numLights;
uniform bool fogEnabled;
uniform int fogType;
uniform vec3 fogColor;

void main()
{
    if (!passThrough && shadeInFrag) {
        vec3 eyeNormal = normalize(normalMatrix * v_normal);
        vec4 diffuseColor = vec4(1.0, 1.0, 1.0, 1.0);
#ifndef LITE_SHADER
        vec4 brightness = vec4(0.0, 0.0, 0.0, 0.0);
        
        for (int i = 0; i < numLights; i++) {
            Light l = lights[i];
            vec3 lightPosition;
            float nDotVP;
            
            switch (l.type) {
                case LIGHT_TYPE_DIRECTIONAL:
                    lightPosition = vec3(-l.direction.x, -l.direction.y, -l.direction.z);
                    nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
                    brightness += vec4(nDotVP * l.color, 0.0);
                    break;
                case LIGHT_TYPE_SPOT:
                    lightPosition = vec3(-l.direction.x, -l.direction.y, -l.direction.z);
                    nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
                    vec3 lightDistDir = normalize(v_position - l.position);
                    float dirDotDist = max(0.0, dot(lightDistDir, normalize(-lightPosition)));
                    brightness += dirDotDist > cos(l.size) ? vec4(nDotVP * l.color, 0.0) : vec4(0, 0, 0, 0);
                    break;
                case LIGHT_TYPE_AMBIENT:
                    brightness += vec4(l.color, 0);
                    break;
            }
        }
        
        if (fogEnabled) {
            // Perform fog calculation
            float fogFactor = 1.0;
            if (fogType == 0) {
                // Linear fog
                float fogMin = 3.0;
                float fogMax = 14.0;
                fogFactor = clamp((fogMax - length(v_localPosition)) / (fogMax - fogMin), 0.0, 1.0);
            }
            else {
                // Exponential fog
                float density = 0.15;
                float exponent = length(v_localPosition) * density;
                fogFactor = clamp(1.0 / exp(exponent), 0.0, 1.0);
            }
            o_fragColor = brightness * diffuseColor * texture(texSampler, v_texcoord) * fogFactor + vec4(fogColor, 0) * (1.0  - fogFactor);
        }
        else {
            o_fragColor = brightness * diffuseColor * texture(texSampler, v_texcoord);
        }

#else
        o_fragColor = diffuseColor * texture(texSampler, v_texcoord);
#endif
    } else {
        o_fragColor = v_color;
    }
}

