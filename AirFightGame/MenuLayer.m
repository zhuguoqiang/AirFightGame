//
//  MenuLayer.m
//  AirFightGame
//
//  Created by 朱国强 on 14-5-16.
//  Copyright 2014年 Apple002. All rights reserved.
//

#import "MenuLayer.h"
#import "PreloadLayer.h"
#import "SettingLayer.h"


@implementation MenuLayer

+(CCScene *) scene
{
    // 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	MenuLayer *layer = [MenuLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;

}

- (id)init
{
    self = [super init];
    if (self) {
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        
        CCMenuItemFont *helloItem = [CCMenuItemFont itemWithString:NSLocalizedString(@"TITLE", nil) target:self selector:@selector(startGame:)];
        
        helloItem.position = ccp(winSize.width/2, winSize.height *0.8);
        
        CCMenuItemFont *startItem = [CCMenuItemFont itemWithString:@"开始游戏" target:self selector:@selector(startGame:)];
        
        startItem.position = ccp(winSize.width/2, winSize.height*0.6);
        
        CCMenuItemFont *settingItem = [CCMenuItemFont itemWithString:@"游戏设置" target:self selector:@selector(setting:)];
        
        settingItem.position = ccp(winSize.width/2, winSize.height *0.4);
        
        CCMenu *menu = [CCMenu menuWithItems:helloItem, startItem, settingItem, nil];
        
        menu.position = CGPointZero;
        
        [self addChild:menu];
    }
    return self;
}

- (void)startGame:(id)sender
{
    
    CCTransitionSlideInL *transitionScene = [CCTransitionSlideInL transitionWithDuration:2.0 scene:[PreloadLayer scene]];
    [[CCDirector sharedDirector] replaceScene:transitionScene];
    
}

- (void)setting:(id)sender
{
    CCTransitionSlideInL *transitionScene = [CCTransitionSlideInL transitionWithDuration:2.0 scene:[SettingLayer scene]];
    [[CCDirector sharedDirector] replaceScene:transitionScene];
}

@end
