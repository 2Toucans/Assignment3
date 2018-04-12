//
//  Light.h
//  Assignment2
//
//  Created by Aaron Freytag on 2018-03-14.
//  Copyright © 2018 2Toucans. All rights reserved.
//

#ifndef Light_h
#define Light_h

enum {
    DIRECTIONAL_LIGHT,
    SPOT_LIGHT,
    AMBIENT_LIGHT
};

typedef struct Light {
    GLint type;
    GLKVector3 color;
    GLKVector3 position;
    GLKVector3 direction;
    GLfloat size;
} Light;

#endif /* Light_h */
