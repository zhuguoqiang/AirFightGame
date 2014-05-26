//
//  FKSprite.h
//  AirFightGame
//
//  Created by 朱国强 on 14-5-19.
//  Copyright 2014年 Apple002. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface FKSprite : CCSprite {
    
}

//精灵的生命值
@property (nonatomic, assign) int lifeValue;
//精灵名称
@property (nonatomic, strong) NSString *name;
//敌机血条
@property (nonatomic, strong) CCProgressTimer *enemyPlaneHP;
//血条更新量
@property (nonatomic, assign) float HPInterval;

@end
