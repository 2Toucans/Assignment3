//
//  Model.h
//  Assignment1
//
//  Created by Aaron Freytag on 2018-02-14.
//  Copyright © 2018 Aaron Freytag. All rights reserved.
//

#ifndef Model_h
#define Model_h
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface Model : NSObject

@property float* vertices;
@property float* normals;
@property float* texCoords;
@property int* indices;
@property int numIndices;
@property GLKMatrix4 position;

@end

#endif /* Model_h */
