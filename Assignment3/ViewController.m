//
//  ViewController.m
//  Assignment2
//
//  Created by Colt King on 2018-02-28.
//  Copyright © 2018 2Toucans. All rights reserved.
//

#import "ViewController.h"
#import "Renderer.h"
#import "EnvironmentController.h"
#import "Game.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *fogSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *dayNightSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *spotlightSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *fogStyleSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *controlSwitch;
@property Boolean controllingModel;

@end

@implementation ViewController
{
    CGPoint swipePos, rotatePos;
    float pinchScale;
    Game* game;
    EnvironmentController* ec;
}

- (IBAction)fogToggled:(id)sender {
    [ec toggleFog];
}

- (IBAction)dayToggled:(id)sender {
    [ec toggleDay];
}

- (IBAction)controlToggled:(id)sender {
    if (_controllingModel || [game playerIsOnModelTile]) {
        _controllingModel = !_controllingModel;
    }
    [_controlSwitch setOn:!_controllingModel];
}

- (IBAction)spotlightToggled:(id)sender {
    [ec toggleSpotLight];
}

- (IBAction)fogStyleToggled:(id)sender {
    [ec toggleFogType];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    GLKView* view = (GLKView *) self.view;
    [Renderer setup:view];
    
    game = [[Game alloc] init];
    ec = [[EnvironmentController alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [Renderer close];
}
- (IBAction)panGesture:(UIPanGestureRecognizer *)sender
{
    if(sender.state == UIGestureRecognizerStateBegan)
    {
        swipePos = CGPointZero;
    }
    
    CGPoint point = [sender translationInView:self.view];
    
    float x = point.x - swipePos.x;
    float y = point.y - swipePos.y;
    
    if (!_controllingModel)
    {
        [game move:x y:y];
    }
    else
    {
        [game moveModel:x y:y];
    }
    
    swipePos = point;
}

- (IBAction)rotateGesture:(UIPanGestureRecognizer *)sender
{
    if(sender.state == UIGestureRecognizerStateBegan)
    {
        rotatePos = CGPointZero;
    }
    
    CGPoint point = [sender translationInView:self.view];
    
    float x = point.x - rotatePos.x;

    if (!_controllingModel)
    {
        [game rotate:x];
    }
    else
    {
        [game rotateModel:x];
    }
    
    rotatePos = point;
}

- (IBAction)tap:(id)sender
{
    // Used to call [game reset]
    // Now instead toggles the model moving autonomously
    [game toggleModelMovement];
}

- (IBAction)doubleTap:(id)sender
{
    //trigger console show
    //tell game to update map
}

- (IBAction)pinch:(UIPinchGestureRecognizer *)sender {
    if(sender.state == UIGestureRecognizerStateBegan)
    {
        pinchScale = 1.0;
    }
    
    float zoom = sender.scale - pinchScale;
    
    if (_controllingModel) {
        [game zoomModel:(1.0 + zoom * 0.5)];
    }
    
    pinchScale = sender.scale;
}

- (void) update
{
    [game update];
}

- (void)glkView:(GLKView*)view drawInRect:(CGRect)rect
{
    [Renderer draw:rect];
}

@end
