//
//  HelloWorldLayer.m
//  AirFightGame
//
//  Created by 朱国强 on 14-5-16.
//  Copyright Apple002 2014年. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "FKSprite.h"

@interface HelloWorldLayer ()
{
    CCSprite *planeSprite;
    
    NSInteger screenWidth, screenHeight;
    
    CCSpriteBatchNode *batchNode;
    
    CCParallaxNode *backgroundNode;//视差视图
    
    //敌机数组
    CCArray *enemyPlaneArray;
    //游戏帧计数器
    NSInteger count;
    
    //代表子弹精灵数组
    CCArray *bulletArray;
    
    ////////
    
    
}

//获取动画帧
- (CCAnimation *)animationByName:(NSString *)animName delay:(float)delay animNum:(int)num;

- (void)updateBackground:(ccTime)delay;

//更新敌机
- (void)updateEnemySprite:(ccTime)delta;

//敌机离开屏幕
- (void)removeEnemySprite:(ccTime)delta;

//更新子弹
- (void)updateShooting:(ccTime)delta;

//子弹离开屏幕
- (void)removeBulletSprite:(ccTime)delta;

//碰撞检测
- (void)collisionDetection:(ccTime)delta;

@end

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer

static NSInteger kTagBatchNode = 1;

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
		batchNode = [CCSpriteBatchNode batchNodeWithFile:@"gameArts.png"];
        batchNode.position = CGPointZero;
        [self addChild:batchNode  z:0 tag:kTagBatchNode];
        
        // 获取屏幕宽度和高度
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        screenWidth = winSize.width;
        screenHeight = winSize.height;
        
//        // 添加背景图片
//        CCSprite *bgSprite = [CCSprite spriteWithSpriteFrameName:@"background_2.png"];
//        bgSprite.position = ccp(screenWidth/2, screenHeight/2);
//        [batchNode addChild:bgSprite];
		

	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

- (void)onEnter
{
    [super onEnter];
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"shoot.mp3" loop:YES];
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:0.5];
    
    // ②添加连续滚动的背景
    backgroundNode = [CCParallaxNode node];
    [self addChild:backgroundNode z:-1];
    // ratio指在CCParallaxNode移动时，添加进去的背景图片精灵的移动速度和CCParallaxNode的比率
    CGPoint ratio = ccp(1.0, 1.0);
    
    NSString *bgName;
    
    if (screenHeight == 480) {
        bgName = @"background_2.png";
    }
    else {
        bgName = @"background_2.png";
    }
    // 第一张背景图
    CCSprite *bgSprite1 = [CCSprite spriteWithSpriteFrameName:bgName];
    //setAliasTexParameters用于解决拼接的地图在连接滚动时容易形成黑色缝隙的问题
    [[bgSprite1 texture] setAliasTexParameters];
    bgSprite1.anchorPoint = ccp(0, 0);
    [backgroundNode addChild:bgSprite1 z:1 parallaxRatio:ratio positionOffset:ccp(0, 0)];
    // 第二张背景图
    CCSprite *bgSprite2 = [CCSprite spriteWithSpriteFrameName:bgName];
    //setAliasTexParameters用于解决拼接的地图在连接滚动时容易形成黑色缝隙的问题
    [[bgSprite2 texture] setAliasTexParameters];
    bgSprite2.anchorPoint = ccp(0, 0);
    // positionOffset时在第2张背景图与第1个背景图拼接处减去1个像素，可以消除地图拼接的缝隙
    [backgroundNode addChild:bgSprite2 z:1 parallaxRatio:ratio positionOffset:ccp(0, bgSprite1.contentSize.height - 1)];
    // 添加开始连续滚动的背景的代码
    
    const int MAX_WIDTH = 320;
    const int MAX_HEIGHT = 480 * 100;
    
    CCSprite *hiddenPlaneSprite = [CCSprite spriteWithSpriteFrameName:@"hero_fly_1.png"];
    hiddenPlaneSprite.visible = NO;
    hiddenPlaneSprite.position = ccp(screenWidth/2, screenHeight/2);
    [batchNode addChild:hiddenPlaneSprite z:-4 tag:1024];
    id move = [CCMoveBy actionWithDuration:300.0f position:ccp(0, MAX_HEIGHT)];
    [hiddenPlaneSprite  runAction:move];
    [backgroundNode runAction:[CCFollow actionWithTarget:hiddenPlaneSprite worldBoundary:CGRectMake(0, 0, MAX_WIDTH, MAX_HEIGHT)]];
    
    
    // ③添加玩家飞机精灵
    planeSprite = [CCSprite spriteWithSpriteFrameName:@"hero_fly_2.png"];
    planeSprite.position = ccp(screenWidth/2, planeSprite.contentSize.height/2+5);
    [batchNode addChild:planeSprite];
    
    // ④玩家飞机动画
    CCAnimation *planeFlyAnimation = [self animationByName:@"hero_fly_" delay:2.0 animNum:2];
    
    id planeFlyAction = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:planeFlyAnimation]];
    
    [planeSprite runAction:planeFlyAction];
    
    // ⑤激活层的touch事件
    [[[CCDirector sharedDirector] touchDispatcher]
     addTargetedDelegate:self priority:0 swallowsTouches:YES];
    
    enemyPlaneArray = [[CCArray alloc]init];
    bulletArray = [[CCArray alloc]init];
    
    // ⑥游戏主循环，每帧都调用的更新方法
    // 这样以默认cocos2d的刷新频率1/60.0s调用(void)update:(ccTime)delta一次
    [self scheduleUpdate];
    
}

#pragma mark - CCTouchOneByOneDelegate

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

// touch updates:
- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    // 把touch坐标转换为局部node坐标
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    // 把旧坐标也转换为局部node坐标
    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
    
    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
    
    oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
    
    // 计算两点的差异，计算touch的偏移量， 把当前点的坐标减去上一个点的坐标
    CGPoint translation = ccpSub(touchLocation, oldTouchLocation);
    
    CGPoint newPos = ccpAdd(planeSprite.position, translation);
    
    planeSprite.position = newPos;
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    
}

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

#pragma mark Update

- (void)update:(ccTime)delta
{
    count++;
    
    [self updateBackground:delta];
    
    [self updateEnemySprite:delta];
    
    [self removeEnemySprite:delta];
    
    [self updateShooting:delta];
    
    [self removeBulletSprite:delta];
    
    [self collisionDetection:delta];
}

#pragma mark Private

- (CCAnimation *)animationByName:(NSString *)animName delay:(float)delay animNum:(int)num
{
    NSMutableArray *animFrames = [NSMutableArray arrayWithCapacity:num];
    for (int i = 1; i<num; i++) {
        //获取动画图片名称
        NSString *frameName = [NSString stringWithFormat:@"%@%d.png",animName, i];
        // 根据图片名称获取动画帧
        CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache]
                                spriteFrameByName:frameName];
        
        [animFrames addObject:frame];
        
    }
    return [CCAnimation animationWithSpriteFrames:animFrames delay:delay];
}

- (void)updateBackground:(ccTime)delay
{
    CCSprite *sprite;
    int index = 0;
    CCARRAY_FOREACH([backgroundNode children], sprite){
        CGPoint pt = [backgroundNode convertToWorldSpace:sprite.position];
        if (pt.y <= -sprite.contentSize.height) {
            [backgroundNode incrementOffset:ccp(0, (sprite.contentSize.height - 1) * 2.0f) forChild:sprite];
            }
        index++;
    }
}

//更新敌机
- (void)updateEnemySprite:(ccTime)delta
{
    //控制count为100的倍数时添加一架敌机
    if (count % 30 == 0)
    {
        FKSprite *enemyPlaneSprite;
        int rand = arc4random() % 2;
        
        int randX = arc4random()% (screenWidth - 40) +20;
        switch (rand) {
            case 0:
            {
                enemyPlaneSprite = [FKSprite spriteWithSpriteFrameName:@"enemy1_fly_1.png"];
                enemyPlaneSprite.position = ccp(randX, 480 + enemyPlaneSprite.contentSize.height);
                enemyPlaneSprite.name = @"enemy1_fly_1";
                enemyPlaneSprite.lifeValue = 1;
            }
                break;
            case 1:
            {
                enemyPlaneSprite = [FKSprite spriteWithSpriteFrameName:@"enemy3_fly_1.png"];
                enemyPlaneSprite.position = ccp(randX, 480 + enemyPlaneSprite.contentSize.height);
                enemyPlaneSprite.name = @"enemy3_fly_1";
                enemyPlaneSprite.lifeValue = 1;
            }
                break;
            case 2:
            {
//                enemyPlaneSprite = [FKSprite spriteWithSpriteFrameName:@"enemy3_fly_1.png"];
//                enemyPlaneSprite.position = ccp(randX, 480 + enemyPlaneSprite.contentSize.height);
//                enemyPlaneSprite.name = @"enemy3_fly_1";
//                enemyPlaneSprite.lifeValue = 1;
            }
                break;
            case 3:
            {
//                enemyPlaneSprite = [FKSprite spriteWithSpriteFrameName:@"enemy4_fly_1.png"];
//                enemyPlaneSprite.position = ccp(randX, 480 + enemyPlaneSprite.contentSize.height);
//                enemyPlaneSprite.name = @"enemy4_fly_1";
//                enemyPlaneSprite.lifeValue = 1;
            }
                break;
            case 4:
            {
//                enemyPlaneSprite = [FKSprite spriteWithSpriteFrameName:@"enemy5_fly_1.png"];
//                enemyPlaneSprite.position = ccp(randX, 480 + enemyPlaneSprite.contentSize.height);
//                enemyPlaneSprite.name = @"enemy5_fly_1";
//                enemyPlaneSprite.lifeValue = 1;
            }
                break;
                
            default:
                break;
        }
        
        //获取随机时间（敌机俯冲时间）
        float durationTime = arc4random() % 2 + 2;
        
        //敌机俯冲
        id moveBy = [CCMoveBy actionWithDuration:durationTime
                                        position:ccp(0, -enemyPlaneSprite.position.y - enemyPlaneSprite.contentSize.height)];
        [enemyPlaneSprite runAction:moveBy];
        
        //将敌机精灵添加到敌机数组
        [enemyPlaneArray addObject:enemyPlaneSprite];
        
        //获得精灵表单
        CCSpriteBatchNode *spriteBatchNode = (CCSpriteBatchNode *)[self getChildByTag:kTagBatchNode];
        
        [spriteBatchNode addChild:enemyPlaneSprite z:4];
    }
    else
    {
        if (count % 200 == 0)
        {
            int randX = arc4random()%(screenWidth - 40) + 20;
            
            //FKSprite精灵继承自CCSprite,增加了生名值
            FKSprite *enemyPlaneSprite;
            
            //创建大敌机
            enemyPlaneSprite = [FKSprite spriteWithSpriteFrameName:@"enemy2_fly_1.png"];
            enemyPlaneSprite.position = ccp(randX, 480 + enemyPlaneSprite.contentSize.height);
            enemyPlaneSprite.name = @"enemy2_fly_1";
            enemyPlaneSprite.lifeValue = 10;
            
            //获取随机时间
            float durationTime = arc4random()%2 + 2;
            
            //敌机俯冲
            id moveBy = [CCMoveBy actionWithDuration:durationTime position:ccp(0, -enemyPlaneSprite.position.y - enemyPlaneSprite.contentSize.height)];
            
            [enemyPlaneSprite runAction:moveBy];
            
            //将敌机添加到数组中
            [enemyPlaneArray addObject:enemyPlaneSprite];
            
            //获得精灵表单
            CCSpriteBatchNode *spriteBatchNode = (CCSpriteBatchNode *)[self getChildByTag:kTagBatchNode];
            
            [spriteBatchNode addChild:enemyPlaneSprite z:4];
            
            //创建一个进度条精灵
            
//            CCSprite *barSprite = [CCSprite spriteWithSpriteFrameName:@""];
            CCSprite *barSprite = [CCSprite spriteWithFile:@"progress_bar.png"];
            
            //初始化一个CCProgressTimer对象
            
            CCProgressTimer *enemyPlaneHP = [CCProgressTimer progressWithSprite:barSprite];
            
            // setPercentage:0.0F 表示并未加载任何资源，表现在画面上就是什么也看不见
            [enemyPlaneHP setPercentage:0.0f];
            
            // 由于图片大小，把scale设置成0.15，缩小一半
            [enemyPlaneHP setScale:0.5];
            
            enemyPlaneHP.midpoint = ccp(0, 0.5);
            
            enemyPlaneHP.barChangeRate = ccp(1, 0);
            
            enemyPlaneHP.type = kCCProgressTimerTypeBar;
            
            enemyPlaneHP.percentage = 100;
            
            CGPoint pos = enemyPlaneSprite.position;
            
            enemyPlaneHP.position = ccp(pos.x, pos.y + 32);
            
            [self addChild:enemyPlaneHP];
            
            id moveBy2 = [CCMoveBy actionWithDuration:durationTime position:ccp(0, -enemyPlaneSprite.position.y - enemyPlaneSprite.contentSize.height)];
            
            [enemyPlaneHP runAction:moveBy2];
            
            enemyPlaneSprite.enemyPlaneHP = enemyPlaneHP;
            
            enemyPlaneSprite.HPInterval = 100.0/(float)enemyPlaneSprite.lifeValue;
        }
    }
}

//敌机离开屏幕
- (void)removeEnemySprite:(ccTime)delta
{
    //获的精灵表单
    CCSpriteBatchNode *spriteBatchNode = (CCSpriteBatchNode *)[self getChildByTag:kTagBatchNode];
    
    //定义循环变量
    CCSprite *enemyPlaneSprite;
    
    //遍历所有的敌机
    
    CCARRAY_FOREACH(enemyPlaneArray, enemyPlaneSprite){
        //如果敌机移出屏幕，删除敌机精灵
        if (enemyPlaneSprite.position.y < -enemyPlaneSprite.contentSize.height) {
            //从精灵表单中删除敌机
            [spriteBatchNode removeChild:enemyPlaneSprite cleanup:YES];
            
            //从敌机数组中删除
            [enemyPlaneArray removeObject:enemyPlaneSprite];
        }
    }
}

//更新子弹
- (void)updateShooting:(ccTime)delta
{
    //获取精灵表单
    CCSpriteBatchNode *spriteBatchNode = (CCSpriteBatchNode *)[self getChildByTag:kTagBatchNode];
    
    //飞机精灵坐标
    CGPoint pos = [planeSprite position];
    
    //控制count位8的倍数是发射子弹
    if (count%8 == 0) {
        //创建子弹精灵
        CCSprite *bulletSprite = [CCSprite spriteWithSpriteFrameName:@"bullet1.png"];
        
        //设置子弹坐标
        CGPoint bulletPos = ccp(pos.x, planeSprite.contentSize.height + bulletSprite.contentSize.height);
        
        bulletSprite.position = bulletPos;
        
        //子弹移动
        id moveBy = [CCMoveBy actionWithDuration:0.4f position:ccp(0, screenHeight)];
        
        [bulletSprite runAction:moveBy];
        
        //将子弹精灵添加到子弹精灵表单
        [spriteBatchNode addChild:bulletSprite z:4];
        
        //将子弹精灵添加到子弹精灵数组
        [bulletArray addObject:bulletSprite];
    }


}

//子弹离开屏幕
- (void)removeBulletSprite:(ccTime)delta
{
    //获得精灵表单
    CCSpriteBatchNode *spriteBatchNode = (CCSpriteBatchNode *)[self getChildByTag:kTagBatchNode];
    
    CCSprite *bulletSprite;
    
    //遍历所有子弹
    CCARRAY_FOREACH(bulletArray, bulletSprite){
        //如果子弹已经移出屏幕，删除子弹
        if (bulletSprite.position.y >= screenHeight) {
            //从精灵表单删除该子弹精灵
            [spriteBatchNode removeChild:bulletSprite cleanup:YES];
            
            //从子弹数组中删除该子弹精灵
            [bulletArray removeObject:bulletSprite];
        }
    }
}

//碰撞检测
- (void)collisionDetection:(ccTime)delta
{
    //获取精灵表单
    CCSpriteBatchNode *spriteBatchNode = (CCSpriteBatchNode *)[self getChildByTag:kTagBatchNode];
    
    //定义循环变量
    FKSprite *enemyPlaneSprite;
    
    CCSprite *bulletSprite;
    
    //遍历敌机数组
    CCARRAY_FOREACH(enemyPlaneArray, enemyPlaneSprite){
        //玩家飞机和敌机发生碰撞
        if (CGRectIntersectsRect(planeSprite.boundingBox, enemyPlaneSprite.boundingBox)) {
            //播放爆炸动画
            [self bombAnimate:@"enemy1_blowup_" position:enemyPlaneSprite.position];
            
            //删除敌机精灵
            [enemyPlaneArray removeObject:enemyPlaneSprite];
            
            [spriteBatchNode removeChild:enemyPlaneSprite cleanup:YES];
            
            [planeSprite stopAllActions];
            
//            [backgroundNode stopAllActions];
            
            //删除玩家精灵
            [spriteBatchNode removeChild:planeSprite cleanup:YES];
            
            [self gameOver:@"Game Over"];
        
        }
        
        //遍历子弹数组
        CCARRAY_FOREACH(bulletArray, bulletSprite){
            
            //如果敌机与子弹发生碰撞
            if (CGRectIntersectsRect(enemyPlaneSprite.boundingBox, bulletSprite.boundingBox)) {
                
                //播放子弹音效
                [[SimpleAudioEngine sharedEngine] playEffect:@"shoot.mp3"];
                
                //删除子弹精灵
                [bulletArray removeObject:bulletSprite];
                
                [spriteBatchNode removeChild:bulletSprite cleanup:YES];
                
                //敌机生命值减一
                enemyPlaneSprite.lifeValue--;
                
                //血条减少
                if (enemyPlaneSprite.enemyPlaneHP != nil) {
                    enemyPlaneSprite.enemyPlaneHP.percentage = enemyPlaneSprite.HPInterval *enemyPlaneSprite.lifeValue;
                }
                
                //判断敌机生命值
                if (enemyPlaneSprite.lifeValue <= 0) {
                    //播放爆炸动画
                    [self bombAnimate:@"enemy1_blowup_" position:enemyPlaneSprite.position];
                    
                    //删除敌机精灵
                    [enemyPlaneArray removeObject:enemyPlaneSprite];
                    
                    [spriteBatchNode removeChild:enemyPlaneSprite cleanup:YES];
                    
                    //播放爆炸音效
                    [[SimpleAudioEngine sharedEngine] playEffect:@"explosion.mp3"];
                    
                }
                break;
            
            
            }
        }
    }
    
}

- (void)bombAnimate:(NSString *)name position:(CGPoint)position
{
    NSString *bombName = [NSString stringWithFormat:@"%@1.png",name];
    
    float delay = 0.08f;
    
    CCSpriteBatchNode *spriteBatchNode = (CCSpriteBatchNode *)[self getChildByTag:kTagBatchNode];
    
    CCSprite *blastSprite = [CCSprite spriteWithSpriteFrameName:bombName];
    
    blastSprite.position = position;
    
    //获得帧动画
    CCAnimation *blastAnimation = [self animationByName:name delay:delay animNum:4];
    
    //组合动画
    id acion = [CCSequence actions:[CCAnimate actionWithAnimation:blastAnimation],
                [CCCallBlock actionWithBlock:^{
        [spriteBatchNode removeChild:blastSprite cleanup:YES];
    }], nil];
    
    [blastSprite runAction:acion];
    
    [spriteBatchNode addChild:blastSprite z:4];
}

- (void)gameOver:(NSString *)str
{
    //停止所有动作
    [self unscheduleUpdate];
    
    //停止声音
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    
    //游戏结束
    
    CCMenuItemFont *gameItem = [CCMenuItemFont itemWithString:str target:self selector:@selector(onRestartGame:)];
    
    gameItem.position = ccp(screenWidth/2, screenHeight/2);
    
    CCMenu *menu = [CCMenu menuWithItems:gameItem, nil];
    
    menu.position = CGPointZero;
    
    [self addChild:menu];
}

@end
