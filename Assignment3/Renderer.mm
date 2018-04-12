//
//  Renderer.m
//  Assignment2
//
//  Created by Aaron F on 2018-03-12.
//  Copyright © 2018 2Toucans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <chrono>
#include "GLESRenderer.hpp"
#include "Renderer.h"
#include "EnvironmentController.h"

enum {
    UNIFORM_MVP_MATRIX,
    UNIFORM_MV_MATRIX,
    UNIFORM_M_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_PASS,
    UNIFORM_SHADEINFRAG,
    UNIFORM_TEXTURE,
    UNIFORM_FOG_ENABLED,
    UNIFORM_FOG_TYPE,
    UNIFORM_FOG_COLOR,
    NUM_UNIFORMS
};

enum {
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBS
};

GLint uniforms[NUM_UNIFORMS];
GLint uniforms2D[NUM_UNIFORMS];
GLKView* view;
GLESRenderer glesRenderer;
GLuint program;
GLuint program2D;
std::chrono::time_point<std::chrono::steady_clock> prevFrameTime;

NSMutableDictionary* models;
NSMutableDictionary* textures;
NSMutableArray* lights;

GLKMatrix3 normalMatrix;
GLKMatrix4 perspectiveMatrix;
GLKMatrix4 cameraMatrix;
float bgColor[] = {0.2f, 0.7f, 0.95f, 0.0f};

bool fogOn = false;
int fogType = 0;
GLKVector3 fogColor = GLKVector3Make(0.0, 0.0, 0.0);

@interface Renderer ()
+ (bool)setupShaders;
+ (void)loadTexture: (NSString*)fileName;
@end

@implementation Renderer

+ (void)setup: (GLKView*)v {
    v.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!v.context) {
        NSLog(@"Failed to create ES 3.0 context");
        NSException *contextFailedException = [NSException
                                               exceptionWithName:@"GLESFailureException"
                                               reason:@"Failed to create context"
                                               userInfo: nil];
        @throw contextFailedException;
    }
    
    v.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view = v;
    
    [EAGLContext setCurrentContext:view.context];
    
    if (![self setupShaders]) {
        NSLog(@"Failed to initialize shaders");
        NSException *contextFailedException = [NSException
                                               exceptionWithName:@"GLESFailureException"
                                               reason:@"Failed to initialize shaders"
                                               userInfo: nil];
        @throw contextFailedException;
    }
    
    glClearColor(bgColor[0], bgColor[1], bgColor[2], bgColor[3]);
    glEnable(GL_DEPTH_TEST);
    prevFrameTime = std::chrono::steady_clock::now();
    
    models = [[NSMutableDictionary alloc] init];
    textures = [[NSMutableDictionary alloc] init];
    lights = [[NSMutableArray alloc] init];
    cameraMatrix = GLKMatrix4Identity;
    
    EnvironmentController* e = [[EnvironmentController alloc] init];
    [e toggleFog];
    
    [Renderer moveCamera:0.5 y:0.2 z:3.5];
}

+ (void)close {
    glDeleteProgram(program);
}

+ (void)draw: (CGRect)drawRect {
    
    // Set up the light uniforms
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram(program);
    
    for (int i = 0; i < [lights count]; i++) {
        Light* light;
        [lights[i] getValue:&light];
        glUniform1i(glGetUniformLocation(program, [[NSString stringWithFormat:@"lights[%d]%@", i, @".type"] UTF8String]), light->type);
        glUniform3f(glGetUniformLocation(program, [[NSString stringWithFormat:@"lights[%d]%@", i, @".color"] UTF8String]), light->color.r, light->color.g, light->color.b);
        glUniform3f(glGetUniformLocation(program, [[NSString stringWithFormat:@"lights[%d]%@", i, @".position"] UTF8String]), light->position.x, light->position.y, light->position.z);
        glUniform3f(glGetUniformLocation(program, [[NSString stringWithFormat:@"lights[%d]%@", i, @".direction"] UTF8String]), light->direction.x, light->direction.y, light->direction.z);
        glUniform1f(glGetUniformLocation(program, [[NSString stringWithFormat:@"lights[%d]%@", i, @".size"] UTF8String]), light->size);
    }
    
    glUniform1i(glGetUniformLocation(program, "numLights"), (GLuint)[lights count]);
    
    [models enumerateKeysAndObjectsUsingBlock:^(NSString* texture, NSMutableArray* models, BOOL* stop) {
        glUniform1i(uniforms[UNIFORM_TEXTURE], (unsigned int)[textures[texture] intValue]);
        glUniform1i(uniforms[UNIFORM_PASS], false);
        glUniform1i(uniforms[UNIFORM_SHADEINFRAG], true);
        glUniform1i(uniforms[UNIFORM_FOG_ENABLED], fogOn);
        glUniform1i(uniforms[UNIFORM_FOG_TYPE], fogType);
        glUniform3f(uniforms[UNIFORM_FOG_COLOR], fogColor.r, fogColor.g, fogColor.b);
        
        for (int i = 0; i < [models count]; i++) {
            Model* m = models[i];
            
            GLuint vao;
            GLuint vbos[3];
            GLuint evbo;
            
            // Generate the vertex buffers and arrays
            glGenVertexArrays(1, &vao);
            
            glGenBuffers(3, vbos);
            glGenBuffers(1, &evbo);
            
            GLKMatrix4 mvpMatrix = m.position;
            normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(mvpMatrix), NULL);
            glUniformMatrix4fv(uniforms[UNIFORM_M_MATRIX], 1, FALSE, (const float *)mvpMatrix.m);
            
            float aspect = (float)view.drawableWidth / (float)view.drawableHeight;
            perspectiveMatrix = GLKMatrix4MakePerspective(60.0f * M_PI / 180.0f, aspect, 0.01f, 200.0f);
            
            mvpMatrix = GLKMatrix4Multiply(GLKMatrix4Invert(cameraMatrix, FALSE), mvpMatrix);
            glUniformMatrix4fv(uniforms[UNIFORM_MV_MATRIX], 1, FALSE, (const float *)mvpMatrix.m);
            mvpMatrix = GLKMatrix4Multiply(perspectiveMatrix, mvpMatrix);
            
            glUniformMatrix4fv(uniforms[UNIFORM_MVP_MATRIX], 1, FALSE, (const float *)mvpMatrix.m);
            glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, normalMatrix.m);
            
            glViewport(0, 0, (int)view.drawableWidth, (int)view.drawableHeight);
            
            glBindVertexArray(vao);
            
            glBindBuffer(GL_ARRAY_BUFFER, vbos[0]);
            glBufferData(GL_ARRAY_BUFFER, m.numIndices * sizeof(float) * 3, m.vertices, GL_STATIC_DRAW);
            glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), 0);
            glEnableVertexAttribArray(0);
            
            glVertexAttrib4f(1, 1.0f, 1.0f, 1.0f, 1.0f);
            
            glBindBuffer(GL_ARRAY_BUFFER, vbos[1]);
            glBufferData(GL_ARRAY_BUFFER, m.numIndices * sizeof(float) * 3, m.normals, GL_STATIC_DRAW);
            glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), 0);
            glEnableVertexAttribArray(2);
            
            glBindBuffer(GL_ARRAY_BUFFER, vbos[2]);
            glBufferData(GL_ARRAY_BUFFER, m.numIndices * sizeof(float) * 2, m.texCoords, GL_STATIC_DRAW);
            glVertexAttribPointer(3, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
            glEnableVertexAttribArray(3);
            
            glUniformMatrix4fv(uniforms[UNIFORM_MVP_MATRIX], 1, FALSE, (const float *)mvpMatrix.m);
            
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, evbo);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, m.numIndices * sizeof(int), m.indices, GL_STATIC_DRAW);
            glDrawElements(GL_TRIANGLES, m.numIndices, GL_UNSIGNED_INT, 0);
            
            glDeleteBuffers(3, vbos);
            glDeleteBuffers(1, &evbo);
            glDeleteVertexArrays(1, &vao);
        }
    }];
    
    glClear(GL_DEPTH_BUFFER_BIT);
    glUseProgram(program2D);
}

+ (void)addModel: (Model*)model texture:(NSString*)texture {
    if ([models objectForKey:texture] == nil) {
        [models setObject:[[NSMutableArray alloc] init] forKey:texture];
        [Renderer loadTexture:texture];
    }
    
    [models[texture] addObject:model];
}

+ (void)moveCamera:(float)x y:(float)y z:(float)z {
    cameraMatrix = GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4Identity, x, y, z), cameraMatrix);
}

+ (void)moveCameraRelative:(float)x y:(float)y z:(float)z {
    cameraMatrix = GLKMatrix4Translate(cameraMatrix, x, y, z);
}

+ (void)rotateCamera:(float)angle x:(float)x y:(float)y z:(float)z {
    cameraMatrix = GLKMatrix4Rotate(cameraMatrix, -angle, x, y, z);
}

+ (GLKMatrix4)getCameraMatrix {
    return cameraMatrix;
}

+ (bool)setupShaders {
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource: [[NSString stringWithUTF8String:"Shader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource: [[NSString stringWithUTF8String:"Shader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    program = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (program == 0) {
        return false;
    }
    
    vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource: [[NSString stringWithUTF8String:"Shader2D.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader2D.vsh"] pathExtension]] cStringUsingEncoding:1]);
    fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource: [[NSString stringWithUTF8String:"Shader2D.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader2D.fsh"] pathExtension]] cStringUsingEncoding:1]);
    program2D = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (program2D == 0) {
        return false;
    }
    
    uniforms[UNIFORM_MVP_MATRIX] = glGetUniformLocation(program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_MV_MATRIX] = glGetUniformLocation(program, "modelViewMatrix");
    uniforms[UNIFORM_M_MATRIX] = glGetUniformLocation(program, "modelMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(program, "normalMatrix");
    uniforms[UNIFORM_PASS] = glGetUniformLocation(program, "passThrough");
    uniforms[UNIFORM_SHADEINFRAG] = glGetUniformLocation(program, "shadeInFrag");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(program, "texSampler");
    uniforms[UNIFORM_FOG_ENABLED] = glGetUniformLocation(program, "fogEnabled");
    uniforms[UNIFORM_FOG_TYPE] = glGetUniformLocation(program, "fogType");
    uniforms[UNIFORM_FOG_COLOR] = glGetUniformLocation(program, "fogColor");
    
    uniforms2D[UNIFORM_MVP_MATRIX] = glGetUniformLocation(program2D, "modelViewProjectionMatrix");
    uniforms2D[UNIFORM_PASS] = glGetUniformLocation(program2D, "passThrough");
    uniforms2D[UNIFORM_SHADEINFRAG] = glGetUniformLocation(program2D, "shadeInFrag");
    
    return true;
}

+ (void)loadTexture:(NSString *)fileName {
    CGImageRef img = [UIImage imageNamed:fileName].CGImage;
    if (!img) {
        NSLog(@"Failed to load image: %@", fileName);
        NSException *contextFailedException = [NSException
                                               exceptionWithName:@"GLESFailureException"
                                               reason:@"Failed to load image"
                                               userInfo: nil];
        @throw contextFailedException;
    }
    
    size_t w = CGImageGetWidth(img);
    size_t h = CGImageGetHeight(img);
    
    GLubyte* spriteData = (GLubyte *)calloc(w * h * 4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, w, h, 8, w*4, CGImageGetColorSpace(img), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, w, h), img);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    
    int val = (int)[textures count];
    
    glActiveTexture(GL_TEXTURE0 + val);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)w, (int)h, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    free(spriteData);
    
    
    NSLog(@"Texture %@ loaded into texture %d", fileName, val);
    
    [textures setObject:[NSNumber numberWithInt:val] forKey:fileName];
    
}

+ (void)addLight:(Light *)light {
    [lights addObject:[NSValue valueWithPointer:light]];
}

+ (void)setFog:(bool)enabled type:(int)type color:(GLKVector3)color {
    fogOn = enabled;
    fogType = type;
    fogColor = color;
}

+ (void)setBackground:(GLKVector3)color {
    bgColor[0] = color.r;
    bgColor[1] = color.g;
    bgColor[2] = color.b;
    
    glClearColor(bgColor[0], bgColor[1], bgColor[2], bgColor[3]);
}

@end


