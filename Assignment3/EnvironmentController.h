//
//  EnvironmentController.h
//  Assignment2
//
//  Created by Aaron F on 2018-03-14.
//  Copyright © 2018 2Toucans. All rights reserved.
//

#ifndef EnvironmentController_h
#define EnvironmentController_h

#include <GLKit/GLKit.h>
#include "Light.h"

@interface EnvironmentController : NSObject {
    Light* ambientLight;
    Light* sunLight;
    Light* spotLight;
    
    bool isNight;
    bool isFoggy;
    GLKVector3 fogColor;
    GLKVector3 skyColor;
    int fogType;
    bool spotLightOn;
}

- (EnvironmentController*) init;

- (void) toDay;

- (void) toNight;

- (void) toggleDay;

- (void) toggleFog;

- (void) toggleFogType;

- (void) toggleSpotLight;

@end

#endif /* EnvironmentController_h */
