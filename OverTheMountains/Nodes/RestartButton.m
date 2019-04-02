//
//  RestartButton.m
//  OverTheMountains
//
//  Created by iCodeWoods on 2019/3/28.
//  Copyright © 2019 iCodeWoods. All rights reserved.
//

#import "RestartButton.h"
#import "GameScene.h"

@implementation RestartButton

- (instancetype)init {
    if (self = [super init]) {
        self.fontSize = 20;
        self.text = @"开爬！";
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    SKTransition *transition = [SKTransition doorsOpenHorizontalWithDuration:0.5];
    [self.scene.view presentScene:[GameScene sceneWithSize:self.scene.view.frame.size] transition:transition];
}

@end
