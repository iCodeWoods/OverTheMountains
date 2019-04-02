//
//  GameScene.m
//  OverTheMountains
//
//  Created by iCodeWoods on 2019/3/28.
//  Copyright © 2019 iCodeWoods. All rights reserved.
//

#import "GameScene.h"
#import "PillarNode.h"
#import "StickNode.h"
#import "PlayerNode.h"
#import "BeginScene.h"

static NSString * const kBackgroundImageName = @"background";

#pragma mark Pillar

static const CGFloat kPillarWidth = 50;
static const CGFloat kPillarHeight = 100;

static const NSUInteger kMaxGapsBetweenPillars = 270;
static const NSUInteger kMinGapsBetweenPillars = 50;

static const NSUInteger kMaxEndPillarWidth = 100;
static const NSUInteger kMinEndPillarWidth = 50;

static const CGFloat kPillarMoveActionDuration = 0.5;

static const CGFloat kRedHeartWidth = 10;
static NSString * const kReadHeartNodeName = @"RedHeartNodeName";

#pragma mark Stick

static const CGFloat kStickWidth = 5;
static const CGFloat kStickGrowSpeed = 24;
static const NSTimeInterval kStickRotateDuration = 0.5;

static const CGFloat kForwardTolerateWidth = 2;
static const CGFloat kAfterwardTolerateWidth = 0.5;

static NSString * const kStickGrowActionName = @"StickGrowActionName";

#pragma mark Player

static const CGFloat kPlayerMoveActionDuration = 1.0;
static const CGFloat kPlayerFallingActionDuration = 0.5;
static NSString * const kPlayerWalkingActionKey = @"PlayerWalkingActionKey";
static NSString * const kPlayerTextureAtlasKey = @"PlayerImages";

@interface GameScene ()

@property (nonatomic, assign) NSUInteger currentLevel;
@property (nonatomic, assign) NSInteger currentScore;

@property (nonatomic, strong) SKLabelNode *scoreLabel;

@property (nonatomic, strong) PillarNode *startPillarNode;
@property (nonatomic, strong) PillarNode *endPillarNode;
@property (nonatomic, strong) PillarNode *nextPillarNode;

@property (nonatomic, strong) StickNode *stickNode;

@property (nonatomic, strong) PlayerNode *playerNode;
@property (nonatomic, strong) NSMutableArray *playerWalkingFrames;

@property (nonatomic, assign) BOOL isPlaying;

@end

@implementation GameScene

- (instancetype)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        [self setupScene];
    }
    return self;
}

- (void)setupScene {
    // Background
    SKSpriteNode *backgroundNode = [[SKSpriteNode alloc] initWithImageNamed:kBackgroundImageName];
    backgroundNode.anchorPoint = CGPointZero;
    backgroundNode.position = CGPointZero;
    backgroundNode.size = self.size;
    [self addChild:backgroundNode];
    
    // Score
    SKLabelNode *scoreNode = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
    scoreNode.text = @"0";
    scoreNode.fontSize = 30;
    scoreNode.fontColor = [UIColor blackColor];
    scoreNode.position = CGPointMake(CGRectGetMidX(self.frame), self.size.height - 100);
    [self addChild:scoreNode];
    self.scoreLabel = scoreNode;
    
    [self addChild:self.startPillarNode];
    self.endPillarNode = [self generateEndPillarNodeWithLevel:self.currentLevel];
    [self addChild:self.playerNode];
}

- (void)overTheMountains:(BOOL)success hitTheRedHeart:(BOOL)hitTheRedHeart {
    CGFloat endPointX = 0;
    if (success) {
        // 如果成功的话，其实不是移至棍子的末端，而是移至终点的末端
        endPointX = CGRectGetMaxX(self.endPillarNode.frame) - CGRectGetWidth(self.playerNode.frame) - kStickWidth;
        self.currentScore += hitTheRedHeart ? 5 : 1;
        NSLog(@"Over the mountains! HitTheRedHeart: %d, Level: %ld, Score: %ld", hitTheRedHeart, self.currentLevel, self.currentScore);
        self.currentLevel++;
    } else {
        // 如果失败的话，移至棍子的末端
        endPointX = MIN(CGRectGetMaxX(self.stickNode.frame), self.size.width - CGRectGetWidth(self.playerNode.frame) / 2);
        NSLog(@"Falling into the cliff! Level: %ld, Score: %ld", self.currentLevel, self.currentScore);
    }
    self.scoreLabel.text = [NSString stringWithFormat:@"%ld", self.currentScore];
    
    // 玩家执行双脚交替行走的动画并前进
    [self.playerNode runAction:[SKAction repeatActionForever:[SKAction animateWithTextures:self.playerWalkingFrames timePerFrame:0.3f resize:NO restore:YES]] withKey:kPlayerWalkingActionKey];
    SKAction *forwardPlayerAction = [SKAction moveToX:endPointX duration:kPlayerMoveActionDuration];
    [self.playerNode runAction:forwardPlayerAction completion:^{
        [self.playerNode removeActionForKey:kPlayerWalkingActionKey];
        
        if (success) {
            dispatch_group_t group = dispatch_group_create();
            
            // 移除起点
            dispatch_group_enter(group);
            SKAction *removeStartPillarAction = [SKAction moveToX:-CGRectGetWidth(self.startPillarNode.frame) duration:0.1];
            [self.startPillarNode runAction:removeStartPillarAction completion:^{
                [self.startPillarNode removeFromParent];
                dispatch_group_leave(group);
            }];
            
            // 红心渐隐
            [self.endPillarNode enumerateChildNodesWithName:kReadHeartNodeName usingBlock:^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
                [node runAction:[SKAction fadeOutWithDuration:kPillarMoveActionDuration] completion:^{
                    [node removeFromParent];
                }];
            }];
            
            // 把终点移至起点的位置
            dispatch_group_enter(group);
            [self.endPillarNode runAction:[SKAction moveToX:0 duration:kPillarMoveActionDuration] completion:^{
                self.startPillarNode = self.endPillarNode;
                self.endPillarNode = [self generateEndPillarNodeWithLevel:self.currentLevel];
                dispatch_group_leave(group);
            }];
            
            // 把玩家移至起点的位置
            dispatch_group_enter(group);
            [self.playerNode runAction:[SKAction moveToX:CGRectGetWidth(self.endPillarNode.frame) - CGRectGetWidth(self.playerNode.frame) - kStickWidth duration:kPillarMoveActionDuration] completion:^{
                dispatch_group_leave(group);
            }];
            
            // 移除棍子
            dispatch_group_enter(group);
            SKAction *removeStickAction = [SKAction moveToX:-CGRectGetWidth(self.stickNode.frame) duration:0.3];
            [self.stickNode runAction:removeStickAction completion:^{
                [self.stickNode removeFromParent];
                self.isPlaying = NO;
                dispatch_group_leave(group);
            }];
            
            // 所有动画完成后的通知，在此重置标记位
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                NSLog(@"Group finished...");
                self.isPlaying = NO;
            });
        } else {
            // 坠入悬崖
            [self.playerNode runAction:[SKAction moveToY:-CGRectGetHeight(self.playerNode.frame) duration:kPlayerFallingActionDuration] completion:^{
                SKTransition *transition = [SKTransition revealWithDirection:SKTransitionDirectionDown duration:0.5];
                [self.view presentScene:[BeginScene sceneWithSize:self.frame.size] transition:transition];
            }];
            [self.stickNode runAction:[SKAction rotateByAngle:-M_PI_2 duration:kStickRotateDuration]];
        }
    }];
}

#pragma mark - Generator

- (PillarNode *)generateEndPillarNodeWithLevel:(NSUInteger)level {
    PillarNode *result;
    
    result = [[PillarNode alloc] initWithColor:[UIColor blackColor] size:CGSizeMake([self randomEndPillarWidthWithLevel:self.currentLevel], kPillarHeight)];
    result.anchorPoint = CGPointZero;
    
    CGFloat originX = CGRectGetMaxX(self.startPillarNode.frame) + [self randomGapsBetweenPillarsWithLevel:self.currentLevel];
    if (level == 0) {
        result.position = CGPointMake(originX, 0);
    } else {
        result.position = CGPointMake(self.size.width, 0);
        [result runAction:[SKAction moveToX:originX duration:kPillarMoveActionDuration]];
    }
    [self addChild:result];
    
    // 生成红心
    SKSpriteNode *redHeartNode = [SKSpriteNode spriteNodeWithColor:[UIColor redColor] size:CGSizeMake(kRedHeartWidth, kRedHeartWidth)];
    redHeartNode.anchorPoint = CGPointZero;
    redHeartNode.position = CGPointMake(CGRectGetWidth(result.frame) / 2 - kRedHeartWidth / 2, CGRectGetHeight(result.frame) - kRedHeartWidth);
    redHeartNode.name = kReadHeartNodeName;
    [result addChild:redHeartNode];
    
    return result;
}

- (CGFloat)randomGapsBetweenPillarsWithLevel:(NSUInteger)level {
    return arc4random() % (kMaxGapsBetweenPillars - kMinGapsBetweenPillars) + kMinGapsBetweenPillars;
}

- (CGFloat)randomEndPillarWidthWithLevel:(NSUInteger)level {
    return arc4random() % (kMaxEndPillarWidth - kMinEndPillarWidth) + kMinEndPillarWidth;
}

#pragma mark - Touch Event

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying) {
        return;
    }
    
    self.stickNode = [StickNode spriteNodeWithColor:[UIColor blackColor] size:CGSizeMake(kStickWidth, kStickWidth)];
    self.stickNode.anchorPoint = CGPointZero;
    self.stickNode.position = CGPointMake(CGRectGetMaxX(self.startPillarNode.frame) - kStickWidth, CGRectGetMaxY(self.startPillarNode.frame));
    [self addChild:self.stickNode];
    
    SKAction *growAction = [SKAction repeatActionForever:[SKAction resizeByWidth:0 height:kStickGrowSpeed duration:0.1]];
    [self.stickNode runAction:growAction withKey:kStickGrowActionName];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying) {
        return;
    }
    self.isPlaying = YES;
    
    [self.stickNode removeActionForKey:kStickGrowActionName];
    [self.stickNode runAction:[SKAction rotateByAngle:-M_PI_2 duration:kStickRotateDuration] completion:^{
        CGFloat stickEndPoint = CGRectGetMaxX(self.stickNode.frame);
        CGFloat endPillarMinPoint = CGRectGetMinX(self.endPillarNode.frame);
        CGFloat endPillarMaxPoint = CGRectGetMaxX(self.endPillarNode.frame);

        BOOL success = stickEndPoint >= endPillarMinPoint - kForwardTolerateWidth && stickEndPoint <= endPillarMaxPoint + kAfterwardTolerateWidth;
        BOOL hitTheRedHeart = fabs(stickEndPoint - (endPillarMinPoint + endPillarMaxPoint) / 2) < kRedHeartWidth / 2;
        [self overTheMountains:success hitTheRedHeart:hitTheRedHeart];
    }];
}

#pragma mark - Getters

- (PillarNode *)startPillarNode {
    if (!_startPillarNode) {
        _startPillarNode = [[PillarNode alloc] initWithColor:[UIColor blackColor] size:CGSizeMake(kPillarWidth, kPillarHeight)];
        _startPillarNode.anchorPoint = CGPointZero;
        _startPillarNode.position = CGPointMake(0, 0);
    }
    
    return _startPillarNode;
}

- (PlayerNode *)playerNode {
    if (!_playerNode) {
        _playerNode = [[PlayerNode alloc] initWithTexture:self.playerWalkingFrames[0]];
        _playerNode.anchorPoint = CGPointZero;
        _playerNode.position = CGPointMake(CGRectGetMaxX(self.startPillarNode.frame) - CGRectGetWidth(_playerNode.frame) - kStickWidth, CGRectGetMaxY(self.startPillarNode.frame));
    }
    
    return _playerNode;
}

- (NSMutableArray *)playerWalkingFrames {
    if (!_playerWalkingFrames) {
        _playerWalkingFrames = [NSMutableArray array];
        SKTextureAtlas *playerAnimatedAtlas = [SKTextureAtlas atlasNamed:kPlayerTextureAtlasKey];
        for (int i = 1; i <= playerAnimatedAtlas.textureNames.count; i++) {
            SKTexture *texture = [playerAnimatedAtlas textureNamed:[NSString stringWithFormat:@"player%d", i]];
            [_playerWalkingFrames addObject:texture];
        }
    }

    return _playerWalkingFrames;
}


@end

