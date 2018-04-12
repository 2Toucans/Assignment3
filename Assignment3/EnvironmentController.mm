//
//  EnvironmentController.m
//  Assignment2
//
//  Created by Aaron F on 2018-03-14.
//  Copyright © 2018 2Toucans. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "EnvironmentController.h"
#include "Renderer.h"

@implementation EnvironmentController
    
- (EnvironmentController*) init {
    self = [super init];
    
    sunLight = (Light*)malloc(sizeof(Light));
    sunLight->color = GLKVector3Make(1.0, 1.0, 0.8);
    sunLight->direction = GLKVector3Make(0.0, -1.0, -0.3);
    sunLight->type = DIRECTIONAL_LIGHT;
    
    [Renderer addLight:sunLight];
    
    spotLight = (Light*)malloc(sizeof(Light));
    spotLight->color = GLKVector3Make(0.0, 0.0, 0.0);
    spotLight->direction = GLKVector3Make(0.0, 0.0, -1.0);
    spotLight->position = GLKVector3Make(0.0, 0.0, 2.0);
    spotLight->size = 0.5;
    spotLight->type = SPOT_LIGHT;
    
    [Renderer addLight:spotLight];
    
    ambientLight = (Light*)malloc(sizeof(Light));
    ambientLight->color = GLKVector3Make(0.3, 0.3, 0.3);
    ambientLight->type = AMBIENT_LIGHT;
    
    [Renderer addLight:ambientLight];
    
    isFoggy = false;
    fogType = 0;
    [self toDay];
    
    return self;
}

- (void) toDay {
    isNight = false;
    sunLight->color = GLKVector3Make(1.0, 1.0, 0.8);
    sunLight->direction = GLKVector3Make(0.0, -1.0, -0.3);
    ambientLight->color = GLKVector3Make(0.3, 0.3, 0.3);
    skyColor = GLKVector3Make(0.2f, 0.7f, 0.95f);
    fogColor = GLKVector3Make(0.3f, 0.8f, 1.0f);
    
    [Renderer setBackground:skyColor];
    [Renderer setFog:isFoggy type:fogType color:fogColor];
}

- (void) toNight {
    isNight = true;
    sunLight->color = GLKVector3Make(0.05, 0.28, 0.65);
    sunLight->direction = GLKVector3Make(0.0, -1.0, 0.3);
    ambientLight->color = GLKVector3Make(0.05, 0.05, 0.05);
    skyColor = GLKVector3Make(0.0, 0.08, 0.25);
    fogColor = GLKVector3Make(0.0, 0.12, 0.3);
    
    [Renderer setBackground:skyColor];
    [Renderer setFog:isFoggy type:fogType color:fogColor];
}

- (void) toggleDay {
    if (isNight) {
        [self toDay];
    }
    else {
        [self toNight];
    }
}

- (void) toggleFog {
    isFoggy = !isFoggy;
    [Renderer setFog:isFoggy type:fogType color:fogColor];
}

- (void) toggleFogType {
    fogType = fogType == 0 ? 1 : 0;
    [Renderer setFog:isFoggy type:fogType color:fogColor];
}

- (void) toggleSpotLight {
    spotLightOn = !spotLightOn;
    if (spotLightOn) {
        spotLight->color = GLKVector3Make(1.5, 1.5, 1.5);
    }
    else {
        spotLight->color = GLKVector3Make(0.0, 0.0, 0.0);
    }
}

@end
