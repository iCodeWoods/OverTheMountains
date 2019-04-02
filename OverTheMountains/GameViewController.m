//
//  GameViewController.m
//  OverTheMountains
//
//  Created by iCodeWoods on 2019/3/28.
//  Copyright © 2019 iCodeWoods. All rights reserved.
//

#import "GameViewController.h"
#import "GameScene.h"
#import "BeginScene.h"

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Configure the view.
    SKView *skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    skView.showsFields = YES;
    skView.showsPhysics = YES;
    skView.showsDrawCount = YES;
    skView.showsQuadCount = YES;
    
    // Create and configure the scene.
    BeginScene *scene = [BeginScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene
    [skView presentScene:scene];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
