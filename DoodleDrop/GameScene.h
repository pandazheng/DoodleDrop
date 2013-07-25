//
//  GameScene.h
//  DoodleDrop
//
//  Created by panda zheng on 13-7-24.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameScene : CCLayer {
    CCSprite *player;
    CGPoint playerVelocity;
    
    CCArray *spiders;
    
    float spiderMoveDuration;
    int numSpidersMoved;
    
    ccTime totalTime;
    int score;
    CCLabelBMFont *scoreLabel;
}

+(id) scene;

-(void) initSpiders;
-(void) resetSpiders;
-(void) spidersUpdate: (ccTime) delta;
-(void) runSpiderMoveSequence: (CCSprite *)spider;
-(void) runSpiderWiggleSequence: (CCSprite *)spider;
-(void) spiderBelowScreen: (id) sender;
-(void) checkForCollision;
-(void) showGameOver;
-(void) resetGame;

@end
