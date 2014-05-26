//
//  PreloadLayer.m
//  AirFightGame
//
//  Created by 朱国强 on 14-5-16.
//  Copyright 2014年 Apple002. All rights reserved.
//

#import "PreloadLayer.h"
#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"


/**
 	 定义一个私有的Category，为了不让API暴露给客户端
 	 将一些类内部所使用的方法和变量放在私有的扩展里面，而不是直接声明在头文件当中
 	 */
@interface PreloadLayer ()
{
    //需要加载的资源总数
    int sourceCount;
    
    //显示进度条的成员变量
    CCProgressTimer *progress;
    
    //进度条更新次数
    float progressInterval;
}
- (void)loadMusics:(NSArray *)musicFiles;
- (void)loadSounds:(NSArray *)soundClips;
- (void)loadSpriteSheets:(NSArray *)spriteSheets;//加载精灵表单
- (void)loadingComplete;//资源全部加载完成，切换到另一个场景
- (void)progressUpdate;//更新进度条

@end


@implementation PreloadLayer

+(CCScene *) scene
{
    // 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	PreloadLayer *layer = [PreloadLayer node];
	
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
        
        CCSprite *barSprite = [CCSprite spriteWithFile:@"progress_bar.png"];
        
        progress = [CCProgressTimer progressWithSprite:barSprite];
        
        [progress setPercentage:0.0f];
        // 由于图片大小关系，把scale设置成0.5，即缩小一半
//        [progress setScale:0.5f];
        // 设置进度条动画的起始位置，默认在图片的中点
        // 如果想要显示从左到右的一个动画效果，必须改成(0,y)
        progress.midpoint = ccp(0, 0.5);
        // barChangeRate表示是否改变水平或者垂直方向的比例，设置成1表示改变，0表示不改变
        progress.barChangeRate = ccp(1, 0);
        // 本例制作一个从左至右的水平进度条，所以midpoint应该是(0,0.5)
        // 因为x方向需要改变，而y方向不需要改变，所以barChangeRate = ccp(1, 0)
        // kCCProgressTimerTypeBar表示为条形进度条
        progress.type = kCCProgressTimerTypeBar;
        //
        [progress setPosition:ccp(winSize.width/2, winSize.height/2)];
        
        [self addChild:progress];
        
        
    }
    return self;
}

- (void)onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];
    
    NSString *path = [[CCFileUtils sharedFileUtils] fullPathFromRelativePath:@"PreloadResources.plist"];
    
    NSDictionary *resources = [NSDictionary dictionaryWithContentsOfFile:path];
    
    NSArray *spriteSheets = [resources objectForKey:@"SpriteSheets"];
    NSArray *sounds = [resources objectForKey:@"Sounds"];
    NSArray *musics = [resources objectForKey:@"Musics"];
    
    sourceCount = spriteSheets.count + sounds.count + musics.count;
    
    progressInterval = 100.0/ (float)sourceCount;
    // 调用performSelectorOnMainThread在主线程上依次加载每种类型的游戏资源
    // waitUntilDone的值为YES能保证所有的资源按照序列依次加载
    if (sounds) {
        [self performSelectorOnMainThread:@selector(loadSounds:) withObject:sounds waitUntilDone:YES];
    }
    if(spriteSheets)
    {
        [self performSelectorOnMainThread:@selector(loadSpriteSheets:) withObject:spriteSheets waitUntilDone:YES];
    }
    if (musics)
    {
        [self performSelectorOnMainThread:@selector(loadMusics:) withObject:musics waitUntilDone:YES];
    }
   
    
    
}

- (void)loadMusics:(NSArray *)musicFiles
{
    for (NSString *music in musicFiles) {
        [[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:music];
        
        [self progressUpdate];
    }
}

- (void)loadSounds:(NSArray *)soundClips
{
    for (NSString *soundClip in soundClips) {
        [[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:soundClip];
        
        [self progressUpdate];
    }
}

//加载精灵表单
- (void)loadSpriteSheets:(NSArray *)spriteSheets
{
    for (NSString *spriteSheet in spriteSheets) {
        // 该方法会加载与该plist文件名称相同但后缀为.png的纹理图片
        // 把该plist的所有spriteFrame信息读取出来
        // 在之后的代码中可以通过spriteFrameWithName获取相应的精灵帧
        // 本例中airfightSheet.plist对应airfightSheet.png
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:spriteSheet];
        
        [self progressUpdate];
    }
}

//资源全部加载完成，切换到另一个场景
- (void)loadingComplete
{
    CCDelayTime *delay = [CCDelayTime actionWithDuration:2.0f];
    
    CCCallBlock *callBlock = [CCCallBlock actionWithBlock:^{
        [[CCDirector sharedDirector] replaceScene:
        [CCTransitionSlideInL transitionWithDuration:1.0f scene:[HelloWorldLayer scene]]];
    }];
    
    CCSequence *sequence = [CCSequence actions:delay, callBlock, nil];
    
    [self runAction:sequence];
    
}

//更新进度条
- (void)progressUpdate
{
    if (--sourceCount) {
        [progress setPercentage:100.0f - (progressInterval * sourceCount)];
    }
    else
    {
        CCProgressFromTo *ac = [CCProgressFromTo actionWithDuration:0.5 from:progress.percentage to:100.0f];
        CCCallBlock *callBack = [CCCallBlock actionWithBlock:^{
            [self loadingComplete];
        }];
        
        id action = [CCSequence actions:ac, callBack, nil];
        
        [progress runAction:action];
    }
}
@end
