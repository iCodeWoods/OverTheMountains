//
//  BeginScene.m
//  OverTheMountains
//
//  Created by iCodeWoods on 2019/4/1.
//  Copyright © 2019 iCodeWoods. All rights reserved.
//

#import "BeginScene.h"
#import "RestartButton.h"

@implementation BeginScene

- (instancetype)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        RestartButton *restartButton = [[RestartButton alloc] init];
        restartButton.position = CGPointMake(size.width/2, size.height/2);
        [self addChild:restartButton];
    }
    
    return self;
}

@end
