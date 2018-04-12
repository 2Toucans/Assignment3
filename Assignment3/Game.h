//
//  Game.h
//  Assignment2
//
//  Created by Colt King on 2018-03-11.
//  Copyright © 2018 2Toucans. All rights reserved.
//

#ifndef Game_h
#define Game_h

#import <Foundation/Foundation.h>
#import "Renderer.h"
#import <GLKit/GLKit.h>
#import "Collisions.h"

@interface Game : NSObject
{
    @private
    int rows, cols;
}

- (void)update;

- (void)move:(float)x y:(float)y;

- (void)rotate:(float)y;

- (void)moveModel:(float)x y:(float)y;

- (void)rotateModel:(float)y;

- (void)zoomModel:(float)zoom;

- (void)reset;

- (Boolean) playerIsOnModelTile;

- (void)toggleModelMovement;

@end

#endif /* Game_h */
