//
//  SettingLayer.m
//  AirFightGame
//
//  Created by 朱国强 on 14-5-16.
//  Copyright 2014年 Apple002. All rights reserved.
//

#import "SettingLayer.h"
#import "MenuLayer.h"
#import "CDAudioManager.h"


@implementation SettingLayer

+(CCScene *) scene
{
    // 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	SettingLayer *layer = [SettingLayer node];
	
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
        
        CCMenuItemFont *musicItem = [CCMenuItemFont itemWithString:@"背景音乐" ];
        
        musicItem.position = ccp(winSize.width*0.4, winSize.height * 0.6);
        
        CCMenuItemFont *musicOn = [CCMenuItemFont itemWithString:@"开"];
        
        CCMenuItemFont *musicOff = [CCMenuItemFont itemWithString:@"关"];
        
        CCMenuItemToggle *musicToggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(change:) items:musicOn, musicOff, nil];
        
        musicToggle.position = ccp(winSize.width * 0.6, winSize.height * 0.6);
        
        CCMenuItemFont *returnItem = [CCMenuItemFont itemWithString:@"返回主菜单" target:self selector:@selector(backToMainLayer:)];
        
        returnItem.position = ccp(winSize.width/2, winSize.height *0.4);
        
        CCMenu *menu = [CCMenu menuWithItems:musicItem, musicToggle, returnItem, nil];
        
        menu.position = CGPointZero;
        
        [self addChild:menu];
        
        NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
        
        if (![userDef boolForKey:@"music"]) {
            musicToggle.selectedIndex = 1;
        }
    }
    return self;
}

- (void)change:(id)sender
{
    if ([CDAudioManager sharedManager].mute) {
        [[CDAudioManager sharedManager] setMute:NO];
    }
    else
    {
        [[CDAudioManager sharedManager]setMute:YES];
    }
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    CCMenuItemToggle *toggle = (CCMenuItemToggle *)sender;
    if (toggle.selectedIndex == 1) {
        [userDef  setBool:NO forKey:@"music"];
    }
    else
    {
        [userDef setBool:YES forKey:@"music"];
    }
}

- (void)backToMainLayer:(id)sender
{
    CCTransitionSlideInL *transitionScene = [CCTransitionSlideInL transitionWithDuration:2.0 scene:[MenuLayer scene]];
    
    [[CCDirector sharedDirector] replaceScene:transitionScene];
    
}
@end
