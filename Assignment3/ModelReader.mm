//
//  ModelReader.m
//  Assignment2
//
//  Created by Aaron Freytag on 2018-04-04.
//  Copyright © 2018 2Toucans. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ModelReader.h"

@interface ModelReader()
+ (void) appendVertex: (NSMutableArray*) vertices :(NSString*) str;
+ (void) appendTextureCoord: (NSMutableArray*) texCoords :(NSString*) str;
+ (void) appendNormal: (NSMutableArray*) normals :(NSString*) str;
+ (void) appendFace: (NSMutableArray*) faces :(NSString*) str;

@end

@implementation ModelReader

+ (Model*) loadModel: (NSString*)res {
    NSString* path = [[NSBundle mainBundle] pathForResource: res ofType: @"obj"];
    NSString* file = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    
    NSArray* lines = [file componentsSeparatedByString:@"\n"];
    
    NSMutableArray* vertices = [[NSMutableArray alloc] init];
    NSMutableArray* textureCoords = [[NSMutableArray alloc] init];
    NSMutableArray* normals = [[NSMutableArray alloc] init];
    NSMutableArray* faces = [[NSMutableArray alloc] init];
    
    for (NSString* s in lines) {
        if ([s length] > 0) {
            switch([s characterAtIndex:0]) {
                case 'v':
                    switch([s characterAtIndex:1]) {
                        case ' ':
                            // Vertex
                            [ModelReader appendVertex:vertices :s];
                            break;
                        case 't':
                            [self appendTextureCoord:textureCoords :s];
                            // Texture Coordinate
                            break;
                        case 'n':
                            [self appendNormal:normals :s];
                            // Vertex Normal
                            break;
                    }
                    break;
                case 'f':
                    [self appendFace:faces :s];
                    // Face
                    break;
            }
        }
    }
    
    NSMutableArray* finalVertices = [[NSMutableArray alloc] init];
    NSMutableArray* finalTexCoords = [[NSMutableArray alloc] init];
    NSMutableArray* finalNormals = [[NSMutableArray alloc] init];
    NSMutableArray* indices = [[NSMutableArray alloc] init];
    
    int ind = 0;
    
    for (NSString* word in faces) {
        NSArray* faceIndices = [word componentsSeparatedByString:@"/"];
        [finalVertices addObject:vertices[([faceIndices[0] intValue] - 1) * 3]];
        [finalVertices addObject:vertices[([faceIndices[0] intValue] - 1) * 3 + 1]];
        [finalVertices addObject:vertices[([faceIndices[0] intValue] - 1) * 3 + 2]];
        [finalTexCoords addObject:textureCoords[([faceIndices[1] intValue] - 1) * 2]];
        [finalTexCoords addObject:textureCoords[([faceIndices[1] intValue] - 1) * 2 + 1]];
        [finalNormals addObject:normals[([faceIndices[2] intValue] - 1) * 3]];
        [finalNormals addObject:normals[([faceIndices[2] intValue] - 1) * 3 + 1]];
        [finalNormals addObject:normals[([faceIndices[2] intValue] - 1) * 3 + 2]];
        [indices addObject:[NSNumber numberWithInt:ind++]];
    }
    
    Model* model = [[Model alloc]  init];
    
    model.vertices = (float*)malloc(sizeof(float) * finalVertices.count);
    model.normals = (float*)malloc(sizeof(float) * finalNormals.count);
    model.texCoords = (float*)malloc(sizeof(float) * finalTexCoords.count);
    model.indices = (int*)malloc(sizeof(int) * indices.count);
    
    for (int i = 0; i < finalVertices.count; i++) {
        model.vertices[i] = [finalVertices[i] floatValue];
    }
    for (int i = 0; i < finalNormals.count; i++) {
        model.normals[i] = [finalNormals[i] floatValue];
    }
    for (int i = 0; i < finalTexCoords.count; i++) {
        if (i % 2 == 1) {
            model.texCoords[i] = 1.0f - [finalTexCoords[i] floatValue];
        }
        else {
            model.texCoords[i] = [finalTexCoords[i] floatValue];
        }
    }
    for (int i = 0; i < indices.count; i++) {
        model.indices[i] = [indices[i] intValue];
    }
    
    model.numIndices = (int)indices.count;
    model.position = GLKMatrix4Identity;
    
    return model;
}

+ (void) appendVertex:(NSMutableArray *)vertices :(NSString *)str {
    NSArray* words = [str componentsSeparatedByString:@" "];
    // Expected 4 words: "v " and then a float for each dimension
    for (int i = 1; i < 4; i++) {
        [vertices addObject:[NSNumber numberWithFloat:[words[i] floatValue]]];
    }
}

+ (void) appendTextureCoord:(NSMutableArray *)texCoords :(NSString *)str {
    NSArray* words = [str componentsSeparatedByString:@" "];
    // Expected 3 words: "v " and then a float for each dimension
    for (int i = 1; i < 3; i++) {
        [texCoords addObject:[NSNumber numberWithFloat:[words[i] floatValue]]];
    }
}

+ (void)appendNormal:(NSMutableArray *)normals :(NSString *)str {
    NSArray* words = [str componentsSeparatedByString:@" "];
    // Expected 3 words: "v " and then a float for each dimension
    for (int i = 1; i < 4; i++) {
        [normals addObject:[NSNumber numberWithFloat:[words[i] floatValue]]];
    }
}

+ (void) appendFace:(NSMutableArray *)faces :(NSString *)str {
    NSArray* words = [str componentsSeparatedByString:@" "];
    // Just append the words; We'll deal with it later
    for (int i = 1; i < 4; i++) {
        [faces addObject:words[i]];
    }
}

@end
