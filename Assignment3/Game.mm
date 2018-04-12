//
//  Game.mm
//  Assignment2
//
//  Created by Colt King on 2018-03-11.
//  Copyright © 2018 2Toucans. All rights reserved.
//

#import "Game.h"
#import "ModelReader.h"
#include <chrono>
#include "GLESRenderer.hpp"
#include <stdlib.h>

static bool vertWalls[4][5] =
{
    {true, true, false, false, true},
    {true, true, true, true, true},
    {true, false, true, true, true},
    {true, false, false, true, true}
};

static bool horizWalls[5][4] =
{
    {true, true, true, true},
    {false, false, true, false},
    {false, false, false, false},
    {false, true, false, false},
    {true, true, true, true}
};

enum Texture
{
    texWallBoth, texWallNone, texWallLeft, texWallRight, texPost, texTile
};

enum ModelType
{
    vWall, hWall, tile, post, cube
};

@implementation Game
{
    std::chrono::time_point<std::chrono::steady_clock> lastTime;
    bool autoMove;
    float yRotate;
    Model* spinCube;
    Model* horseModel;
    GLESRenderer glesRenderer;
    Collisions* collide;
    GLKVector2 gravity;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        rows = 4;
        cols = 4;
        
        collide = [[Collisions alloc] init];
        
        [self setModels];
        
        [self makeCube:0.5 y:0.5 z:0];
        [self makeHorse:0.5 y:2 z:-0.48];
        
        gravity = GLKVector2Make(1, 1);
        
        autoMove = true;
        
        lastTime = std::chrono::steady_clock::now();
    }
    return self;
}

- (void)update
{
    auto currentTime = std::chrono::steady_clock::now();
    auto timeElapsed = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime-lastTime).count();
    lastTime = currentTime;
    
    //deal with spinning cube rotation
    float rot = 0.001f * timeElapsed;
    [spinCube setPosition:GLKMatrix4Rotate(spinCube.position, rot, 0, 1, 0)];
    
    //if you aren't controlling the horse, it will move by itself
    if(autoMove)
    {
        int turn = arc4random_uniform(100);
        
        if(turn < 5)
        {
            float h = sqrt(gravity.x * gravity.x + gravity.y * gravity.y);
            float theta = atan(gravity.y/gravity.x);
            theta += M_PI/12;
            
            gravity.x = h*cos(theta);
            gravity.y = h*sin(theta);
            
            [collide pushHorse:gravity.x y:gravity.y];
        }
        else if(turn < 10)
        {
            float h = sqrt(gravity.x * gravity.x + gravity.y * gravity.y);
            float theta = tan(gravity.y/gravity.x);
            theta -= M_PI/12;
            
            gravity.x = h*cos(theta);
            gravity.y = h*sin(theta);
            
            [collide pushHorse:gravity.x y:gravity.y];
        }
    }
    
    //deal with collisions
    [collide update:rot];
    
    //move horse based on gravity and collisions
    GLKVector2 horseMove = [collide getHorseMove];
    GLKMatrix4 moveM = GLKMatrix4Translate(GLKMatrix4Identity, horseMove.x, 0, horseMove.y);
    [horseModel setPosition:GLKMatrix4Multiply(moveM, horseModel.position)];
    
    NSLog(@"x %1.2f y %1.2f", gravity.x, gravity.y);
}

- (void)move:(float)x y:(float)y
{
    [Renderer moveCameraRelative:x/100 y:0 z:y/100];
}

- (void)rotate:(float)y
{
    [Renderer rotateCamera:y/100 x:0 y:1 z:0];
}

- (void)moveModel:(float)x y:(float)y {
    gravity = GLKVector2Make(x, y);
    [collide pushHorse:x/10 y:y/10];
}

- (void)rotateModel:(float)y
{
    horseModel.position = GLKMatrix4Rotate(horseModel.position, y/100, 0, 1, 0);
}

- (void)zoomModel:(float)zoom {
    horseModel.position = GLKMatrix4Scale(horseModel.position, zoom, zoom, zoom);
}

- (void)reset
{
    //[Renderer setPosition:0 y:0 z:0] something like this
}

//Determines the parameters for the posts, tiles, and walls and sends them to the renderer
- (void)setModels
{
    for(float offX = 0; offX < cols; offX += 1)
    {
        for(float offY = 0; offY < rows; offY += 1)
        {
            //posts
            [self makeModel:post x:offX y:offY z:0 t:texPost];
            
            //tiles
            [self makeModel:tile x:offX+0.5 y:offY+0.5 z:-1 t:texTile];
            
            //vertical walls
            if(vertWalls[(int)offY][(int)offX])
            {
                Texture wallTex = [self whichTexture:true x:(int)offX y:(int)offY];
                [self makeModel:vWall x:offX-0.025 y:offY+0.5 z:0 t:wallTex];
                
                if(wallTex == texWallLeft)
                    wallTex = texWallRight;
                else if(wallTex == texWallRight)
                    wallTex = texWallLeft;
                
                [self makeModel:vWall x:offX+0.025 y:offY+0.5 z:0 t:wallTex];
            }
            
            //horizontal walls
            if(horizWalls[(int)offY][(int)offX])
            {
                Texture wallTex = [self whichTexture:false x:(int)offX y:(int)offY];
                [self makeModel:hWall x:offX+0.5 y:offY-0.025 z:0 t:wallTex];
                
                if(wallTex == texWallLeft)
                    wallTex = texWallRight;
                else if(wallTex == texWallRight)
                    wallTex = texWallLeft;
                
                [self makeModel:hWall x:offX+0.5 y:offY+0.025 z:0 t:wallTex];
            }
        }
        
        //missing row of posts
        [self makeModel:post x:offX y:rows z:0 t:texPost];
        
        //missing row of horizontal walls
        if(horizWalls[rows][(int)offX])
        {
            Texture wallTex = [self whichTexture:false x:(int)offX y:rows];
            [self makeModel:hWall x:offX+0.5 y:rows-0.025 z:0 t:wallTex];
            
            if(wallTex == texWallLeft)
                wallTex = texWallRight;
            else if(wallTex == texWallRight)
                wallTex = texWallLeft;
            
            [self makeModel:hWall x:offX+0.5 y:rows+0.025 z:0 t:wallTex];
        }
    }
    
    for(int offY = 0; offY < rows; offY++)
    {
        //missing column of posts
        [self makeModel:post x:cols y:offY z:0 t:texPost];
        
        //missing column of vertical walls
        if(vertWalls[(int)offY][cols])
        {
            Texture wallTex = [self whichTexture:true x:cols y:(int)offY];
            [self makeModel:vWall x:cols-0.025 y:offY+0.5 z:0 t:wallTex];
            
            if(wallTex == texWallLeft)
                wallTex = texWallRight;
            else if(wallTex == texWallRight)
                wallTex = texWallLeft;
            
            [self makeModel:vWall x:cols+0.025 y:offY+0.5 z:0 t:wallTex];
        }
    }
    
    //missing bottom right post
    [self makeModel:post x:cols y:rows z:0 t:texPost];
}

//Formats the model then sends the pieces to the corresponding arrays in the renderer
- (void)makeModel:(ModelType)type x:(float)xPos y:(float)yPos z:(float)zPos t:(Texture)tex
{
    NSString* fileName;
    Model* model = [[Model alloc] init];
    
    switch(tex)
    {
        case texWallBoth:
            fileName = @"color.jpg";
            break;
        case texWallNone:
            fileName = @"kching.jpg";
            break;
        case texWallLeft:
            fileName = @"beauty.jpg";
            break;
        case texWallRight:
            fileName = @"groovy.jpg";
            break;
        case texPost:
            fileName = @"crate.jpg";
            break;
        case texTile:
            fileName = @"tiger.jpg";
            break;
    }
    
    float* vertices;
    float* normals;
    float* texCoords;
    int* indices;
    
    model = [[Model alloc] init];
    //type: 0 = vertWall, 1 = horizWall, 2 = tile, 3 = post, 4 = cube
    [model setNumIndices:(glesRenderer.GenCube(1.0f, &vertices, &normals, &texCoords, &indices, (int)type))];
    [model setVertices:vertices];
    [model setNormals:normals];
    [model setTexCoords:texCoords];
    [model setIndices:indices];
    [model setPosition:GLKMatrix4Translate(GLKMatrix4Identity, xPos, zPos, yPos)];
    
    [Renderer addModel:model texture:fileName];
    
    float h, w;
    
    switch(type)
    {
        case vWall:
            h = 0.4;
            w = 0.05;
            break;
        case hWall:
            h = 0.05;
            w = 0.4;
            break;
        case tile:
            return;
        case post:
            h = 0.1;
            w = 0.1;
            break;
        case cube:
            h = 0.2;
            w = 0.2;
            break;
    }
    
    [collide addBody:xPos y:yPos w:w h:h];
}

//Determines which textures the wall should have based on surrounding
//walls and its orientation
- (Texture)whichTexture:(bool)vertical x:(int)x y:(int)y
{
    Texture tex;
    
    if(vertical)
    {
        if (x > 0 && vertWalls[x-1][y] && (x+1 > rows || !vertWalls[x+1][y]))
            tex = texWallLeft;
        else if(x < rows && vertWalls[x+1][y] && (x == 0 || !vertWalls[x-1][y]))
            tex = texWallRight;
        else if(x > 0 && x < rows && vertWalls[x-1][y] && vertWalls[x+1][y])
            tex = texWallBoth;
        else
            tex = texWallNone;
    }
    else //horizontal
    {
        if (y > 0 && horizWalls[x][y-1] && (y+1 > cols || !horizWalls[x][y+1]))
            tex = texWallLeft;
        else if(y < cols && horizWalls[x][y+1] && (y == 0 || !horizWalls[x][y-1]))
            tex = texWallRight;
        else if(y > 0 && y < cols && horizWalls[x][y-1] && horizWalls[x][y+1])
            tex = texWallBoth;
        else
            tex = texWallNone;
    }
    
    return tex;
}

//Makes the spinning cube and stores it
- (void)makeCube:(float)xPos y:(float)yPos z:(float)zPos
{
    NSString* fileName = @"crate.jpg";
    spinCube = [[Model alloc] init];
    
    float* vertices;
    float* normals;
    float* texCoords;
    int* indices;
    
    [spinCube setNumIndices:(glesRenderer.GenCube(1.0f, &vertices, &normals, &texCoords, &indices, (int)cube))];
    [spinCube setVertices:vertices];
    [spinCube setNormals:normals];
    [spinCube setTexCoords:texCoords];
    [spinCube setIndices:indices];
    [spinCube setPosition:GLKMatrix4Translate(GLKMatrix4Identity, xPos, zPos, yPos)];
    
    [Renderer addModel:spinCube texture:fileName];
    
    [collide addBody:xPos y:yPos w:0.2 h:0.2];
}

//Makes the spinning cube and stores it
- (void)makeHorse:(float)xPos y:(float)yPos z:(float)zPos
{
    NSString* fileName = @"Horse.png";
    horseModel = [ModelReader loadModel:@"horse"];
    
    [horseModel setPosition:GLKMatrix4Translate(horseModel.position, xPos, zPos, yPos)];
    horseModel.position = GLKMatrix4Scale(horseModel.position, 0.004, 0.004, 0.004);

    [Renderer addModel:horseModel texture:fileName];
    
    [collide addHorse:xPos y:yPos w:0.1 h:0.1];
}

- (Boolean)playerIsOnModelTile
{
    int px = (int)([Renderer getCameraMatrix].m30);
    int py = (int)([Renderer getCameraMatrix].m32);
    int mx = (int)(horseModel.position.m30);
    int my = (int)(horseModel.position.m32);
    return px == mx && py == my;
}

- (void)toggleModelMovement
{
    NSLog(@"Movement toggled");
    autoMove = !autoMove;
}

@end
