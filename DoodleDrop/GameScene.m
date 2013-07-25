//
//  GameScene.m
//  DoodleDrop
//
//  Created by panda zheng on 13-7-24.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "GameScene.h"
#import "SimpleAudioEngine.h"

@interface GameScene (PrivateMethods)



@end


@implementation GameScene

+(id) scene
{
    CCScene *scene = [CCScene node];
    CCLayer *layer = [GameScene node];
    [scene addChild:layer];
    return scene;
}

-(id) init
{
    self = [super init];
    if (self)
    {
        CCLOG(@"%@: %@",NSStringFromSelector(_cmd),self);
        
        self.isAccelerometerEnabled = YES;
        
        player = [CCSprite spriteWithFile:@"alien.png"];
        [self addChild:player z:0 tag:1];
        
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        float imageHeight = [player texture].contentSize.height;
        player.position = CGPointMake(screenSize.width/2, imageHeight/2);
        
        [self scheduleUpdate];
        
        [self initSpiders];
        
        //增加分数标签
        scoreLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"bitmapfont.fnt"];
        scoreLabel.position = CGPointMake(screenSize.width/2,screenSize.height);
        scoreLabel.anchorPoint = CGPointMake(0.5f,1.0f);
        [self addChild:scoreLabel z:-1];
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"blues.mp3" loop:YES];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"alien-sfx.caf"];
        
        srandom(time(NULL));
        
        [self showGameOver];
    }
    
    return self;
}

-(void) dealloc
{
    CCLOG(@"%@: %@",NSStringFromSelector(_cmd),self);
    
    [spiders release];
    [super dealloc];
}


#pragma mark Spiders
-(void) initSpiders
{
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    
    CCSprite *tempSpider = [CCSprite spriteWithFile:@"spider.png"];
    float imageWidth = [tempSpider texture].contentSize.width;
    
    int numSpiders = screenSize.width / imageWidth;
    
    NSAssert(spiders == nil,@"%@: spiders array is already initalized!",NSStringFromSelector(_cmd));
    spiders = [[CCArray alloc] initWithCapacity:numSpiders];
    
    for (int i = 0 ; i < numSpiders ; i++)
    {
        CCSprite *spider = [CCSprite spriteWithFile:@"spider.png"];
        [self addChild:spider z:0 tag:2];
        
        [spiders addObject:spider];
    }
    
    [self resetSpiders];
}

-(void) resetSpiders
{
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    
    CCSprite *tempSpider = [spiders lastObject];
    CGSize imageSize = [tempSpider texture].contentSize;
    
    int numSpiders = [spiders count];
    for (int i = 0 ; i < numSpiders ; i++)
    {
        CCSprite *spider = [spiders objectAtIndex:i];
        spider.position = CGPointMake(imageSize.width * i + imageSize.width * 0.5f,screenSize.height + imageSize.height);
        spider.scale = 1;
        
        [spider stopAllActions];
    }
    
    [self unschedule:@selector(spidersUpdate:)];
    [self schedule:@selector(spidersUpdate:) interval:0.6f];
    
    numSpidersMoved = 0;
    spiderMoveDuration = 8.0f;
}

-(void) spidersUpdate:(ccTime)delta
{
    for (int i = 0 ; i < 10 ; i++)
    {
        int randomSpiderIndex = CCRANDOM_0_1() * [spiders count];
        CCSprite *spider = [spiders objectAtIndex:randomSpiderIndex];
        
        if ([spider numberOfRunningActions] == 0)
        {
            if (i > 0)
            {
                CCLOG(@"Dropping a Spider after %i retries.",i);
            }
            
            [self runSpiderMoveSequence:spider];
            
            break;
        }
    }
}

-(void) runSpiderMoveSequence:(CCSprite *)spider
{
    numSpidersMoved++;
    if (numSpidersMoved % 4 == 0 && spiderMoveDuration > 2.0f)
    {
        spiderMoveDuration -= 0.1f;
    }
    
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    CGPoint hangInTherePosition = CGPointMake(spider.position.x, screenSize.height - 3 * [spider texture].contentSize.height);
    CGPoint belowScreenPosition = CGPointMake(spider.position.x, - (3 * [spider texture].contentSize.height));
    CCMoveTo *moveHang = [CCMoveTo actionWithDuration:4 position:hangInTherePosition];
    CCEaseElasticOut *easeHang = [CCEaseElasticOut actionWithAction:moveHang period:0.8f];
    CCMoveTo *moveEnd = [CCMoveTo actionWithDuration:spiderMoveDuration position:belowScreenPosition];
    CCEaseBackInOut *easeEnd = [CCEaseBackInOut actionWithAction:moveEnd];
    CCCallFuncN *call = [CCCallFuncN actionWithTarget:self selector:@selector(spiderBelowScreen:)];
    CCSequence *sequence = [CCSequence actions:easeHang,easeEnd,call, nil];
    [spider runAction:sequence];
    
//    [self runSpiderWiggleSequence:spider];
}

-(void) runSpiderWiggleSequence:(CCSprite *)spider
{
    CCScaleTo *scaleUp = [CCScaleTo actionWithDuration:CCRANDOM_0_1() * 2 + 1  scale:1.05f];
    CCEaseBackInOut *easeUp = [CCEaseBackInOut actionWithAction:scaleUp];
    CCScaleTo *scaleDown = [CCScaleTo actionWithDuration:CCRANDOM_0_1() * 2 + 1 scale:0.95f];
    CCEaseBackInOut *easeDown = [CCEaseBackInOut actionWithAction:scaleDown];
    CCSequence *scaleSequence = [CCSequence actions:easeUp,easeDown, nil];
    CCRepeatForever *repeatScale = [CCRepeatForever actionWithAction:scaleSequence];
    [spider runAction:repeatScale];
}

-(void) spiderBelowScreen:(id)sender
{
	NSAssert([sender isKindOfClass:[CCSprite class]], @"sender is not of class CCSprite!");
	CCSprite* spider = (CCSprite*)sender;
	
	CGPoint pos = spider.position;
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	pos.y = screenSize.height + [spider texture].contentSize.height;
	spider.position = pos;
}

#pragma mark Accelerometer Input
-(void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	float deceleration = 0.4f;
	float sensitivity = 6.0f;
	float maxVelocity = 100;
    

	playerVelocity.x = playerVelocity.x * deceleration + acceleration.x * sensitivity;
	
	if (playerVelocity.x > maxVelocity)
	{
		playerVelocity.x = maxVelocity;
	}
	else if (playerVelocity.x < -maxVelocity)
	{
		playerVelocity.x = -maxVelocity;
	}
}

#pragma mark update

-(void) update:(ccTime)delta
{
	CGPoint pos = player.position;
	pos.x += playerVelocity.x;
	
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	float imageWidthHalved = [player texture].contentSize.width * 0.5f;
	float leftBorderLimit = imageWidthHalved;
	float rightBorderLimit = screenSize.width - imageWidthHalved;
    
	if (pos.x < leftBorderLimit)
	{
		pos.x = leftBorderLimit;
        
		playerVelocity = CGPointZero;
	}
	else if (pos.x > rightBorderLimit)
	{
		pos.x = rightBorderLimit;
        
		playerVelocity = CGPointZero;
	}
	
	player.position = pos;
	
	[self checkForCollision];
	
	totalTime += delta;
	int currentTime = (int)totalTime;
	if (score < currentTime)
	{
		score = currentTime;
		[scoreLabel setString:[NSString stringWithFormat:@"%i", score]];
	}
}

#pragma mark Collision Checks

-(void) checkForCollision
{
	float playerImageSize = [player texture].contentSize.width;
	float spiderImageSize = [[spiders lastObject] texture].contentSize.width;
	float playerCollisionRadius = playerImageSize * 0.4f;
	float spiderCollisionRadius = spiderImageSize * 0.4f;
	
	float maxCollisionDistance = playerCollisionRadius + spiderCollisionRadius;
	
	int numSpiders = [spiders count];
	for (int i = 0; i < numSpiders; i++)
	{
		CCSprite* spider = [spiders objectAtIndex:i];
		
		if ([spider numberOfRunningActions] == 0)
		{
			continue;
		}
        
		float actualDistance = ccpDistance(player.position, spider.position);
		
		if (actualDistance < maxCollisionDistance)
		{
			[[SimpleAudioEngine sharedEngine] playEffect:@"alien-sfx.caf"];
			
			[self showGameOver];
		}
	}
}

#pragma mark Reset Game
-(void) setScreenSaverEnabled:(bool)enabled
{
	UIApplication *thisApp = [UIApplication sharedApplication];
	thisApp.idleTimerDisabled = !enabled;
}

-(void) showGameOver
{
	[self setScreenSaverEnabled:YES];
    
	CCNode* node;
	CCARRAY_FOREACH([self children], node)
	{
		[node stopAllActions];
	}
    
	CCSprite* spider;
	CCARRAY_FOREACH(spiders, spider)
	{
		[self runSpiderWiggleSequence:spider];
	}
    
	self.isAccelerometerEnabled = NO;
	self.isTouchEnabled = YES;
	
	[self unscheduleAllSelectors];
    
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
    
	CCLabelTTF* gameOver = [CCLabelTTF labelWithString:@"GAME OVER!" fontName:@"Marker Felt" fontSize:60];
	gameOver.position = CGPointMake(screenSize.width / 2, screenSize.height / 3);
	[self addChild:gameOver z:100 tag:100];
	
	CCTintTo* tint1 = [CCTintTo actionWithDuration:2 red:255 green:0 blue:0];
	CCTintTo* tint2 = [CCTintTo actionWithDuration:2 red:255 green:255 blue:0];
	CCTintTo* tint3 = [CCTintTo actionWithDuration:2 red:0 green:255 blue:0];
	CCTintTo* tint4 = [CCTintTo actionWithDuration:2 red:0 green:255 blue:255];
	CCTintTo* tint5 = [CCTintTo actionWithDuration:2 red:0 green:0 blue:255];
	CCTintTo* tint6 = [CCTintTo actionWithDuration:2 red:255 green:0 blue:255];
	CCSequence* tintSequence = [CCSequence actions:tint1, tint2, tint3, tint4, tint5, tint6, nil];
	CCRepeatForever* repeatTint = [CCRepeatForever actionWithAction:tintSequence];
	[gameOver runAction:repeatTint];
	
	CCRotateTo* rotate1 = [CCRotateTo actionWithDuration:2 angle:3];
	CCEaseBounceInOut* bounce1 = [CCEaseBounceInOut actionWithAction:rotate1];
	CCRotateTo* rotate2 = [CCRotateTo actionWithDuration:2 angle:-3];
	CCEaseBounceInOut* bounce2 = [CCEaseBounceInOut actionWithAction:rotate2];
	CCSequence* rotateSequence = [CCSequence actions:bounce1, bounce2, nil];
	CCRepeatForever* repeatBounce = [CCRepeatForever actionWithAction:rotateSequence];
	[gameOver runAction:repeatBounce];
	
	CCJumpBy* jump = [CCJumpBy actionWithDuration:3 position:CGPointZero height:screenSize.height / 3 jumps:1];
	CCRepeatForever* repeatJump = [CCRepeatForever actionWithAction:jump];
	[gameOver runAction:repeatJump];
    
	CCLabelTTF* touch = [CCLabelTTF labelWithString:@"tap screen to play again" fontName:@"Arial" fontSize:20];
	touch.position = CGPointMake(screenSize.width / 2, screenSize.height / 4);
	[self addChild:touch z:100 tag:101];
	
	CCBlink* blink = [CCBlink actionWithDuration:10 blinks:20];
	CCRepeatForever* repeatBlink = [CCRepeatForever actionWithAction:blink];
	[touch runAction:repeatBlink];
}


-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self resetGame];
}

-(void) resetGame
{
	[self setScreenSaverEnabled:NO];
	
	[self removeChildByTag:100 cleanup:YES];
	[self removeChildByTag:101 cleanup:YES];
	
	self.isAccelerometerEnabled = YES;
	self.isTouchEnabled = NO;
	
	[self resetSpiders];
	
	[self scheduleUpdate];
    
	score = 0;
	totalTime = 0;
	[scoreLabel setString:@"0"];
}


-(void) draw
{
//#if DEBUG
//	CCNode* node;
//	CCARRAY_FOREACH([self children], node)
//	{
//		if ([node isKindOfClass:[CCSprite class]] && (node.tag == 1 || node.tag == 2))
//		{
//			CCSprite* sprite = (CCSprite*)node;
//			float radius = [sprite texture].contentSize.width * 0.4f;
//			float angle = 0;
//			int numSegments = 10;
//			bool drawLineToCenter = NO;
//			ccDrawCircle(sprite.position, radius, angle, numSegments, drawLineToCenter);
//		}
//	}
//#endif
//	CGSize screenSize = [[CCDirector sharedDirector] winSize];
//	
//	float threadCutPosition = screenSize.height * 0.75f;
//    
//	CCSprite* spider;
//	CCARRAY_FOREACH(spiders, spider)
//	{
//		if (spider.position.y > threadCutPosition)
//		{
//			float threadX = spider.position.x + (CCRANDOM_0_1() * 2.0f - 1.0f);
//			
//            glColorMask(0.5f, 0.5f, 0.5f, 1.0f);
//			ccDrawLine(spider.position, CGPointMake(threadX, screenSize.height));
//		}
//	}
    [super draw];
}

@end
