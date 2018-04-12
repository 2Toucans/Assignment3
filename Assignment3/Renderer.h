//
//  Renderer.h
//  Assignment2
//
//  Created by Aaron F on 2018-03-12.
//  Copyright © 2018 2Toucans. All rights reserved.
//

#ifndef Renderer_h
#define Renderer_h

#import <Foundation/Foundation.h>
#include "Model.h"
#include "Light.h"

@interface Renderer : NSObject

+ (void)setup: (GLKView*)view;

+ (void)draw: (CGRect)drawRect;

+ (void)close;

+ (void)addModel: (Model*)model texture:(NSString*)texture;

+ (void)addLight: (Light*)light;

+ (void)moveCamera: (float)x y:(float)y z:(float)z;

+ (void)moveCameraRelative: (float)x y:(float)y z:(float)z;

+ (void)rotateCamera:(float)angle x:(float)x y:(float)y z:(float)z;

+ (GLKMatrix4)getCameraMatrix;

+ (void)setFog:(bool)enabled type:(int)type color:(GLKVector3)color;

+ (void)setBackground: (GLKVector3)color;

@end

#endif /* Renderer_h */
