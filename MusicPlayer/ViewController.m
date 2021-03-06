//
//  ViewController.m
//  MusicPlayer
//
//  Created by 李志帅 on 16/7/11.
//  Copyright © 2016年 李志帅. All rights reserved.

//菜鸟一个,不喜勿喷,欢迎大家关注我github,交流学习
//
/*
 1.设置后台运行模式：在plist文件中添加Required background modes，并且设置item 0=App plays audio or streams audio/video using AirPlay（其实可以直接通过Xcode在Project Targets-Capabilities-Background Modes中设置）
 2.设置AVAudioSession的类型为AVAudioSessionCategoryPlayback并且调用setActive::方法启动会话。
 
 AVAudioSession *audioSession=[AVAudioSession sharedInstance];
 [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
 [audioSession setActive:YES error:nil];
 3. 为了能够让应用退到后台之后支持耳机控制，建议添加远程控制事件（这一步不是后台播放必须的）
 
 /////
 前两步是后台播放所必须设置的，第三步主要用于接收远程事件，如果这一步不设置虽然也能够在后台播放，但是无法获得音频控制权（如果在使用当前应用之前使用其他播放器播放音乐的话，此时如果按耳机播放键或者控制中心的播放按钮则会播放前一个应用的音频），并且不能使用耳机进行音频控制。第一步操作相信大家都很容易理解，如果应用程序要允许运行到后台必须设置，正常情况下应用如果进入后台会被挂起，通过该设置可以上应用程序继续在后台运行。但是第二步使用的AVAudioSession有必要进行一下详细的说明。
 
 在iOS中每个应用都有一个音频会话，这个会话就通过AVAudioSession来表示。AVAudioSession同样存在于AVFoundation框架中，它是单例模式设计，通过sharedInstance进行访问。在使用Apple设备时大家会发现有些应用只要打开其他音频播放就会终止，而有些应用却可以和其他应用同时播放，在多种音频环境中如何去控制播放的方式就是通过音频会话来完成的
 
 会话类型                       说明
 AVAudioSessionCategoryAmbient	混音播放，可以与其他音频应用同时播放
 AVAudioSessionCategorySoloAmbient	独占播放
 AVAudioSessionCategoryPlayback	后台播放，也是独占的
 AVAudioSessionCategoryRecord	录音模式，用于录音时使用
 AVAudioSessionCategoryPlayAndRecord	播放和录音，此时可以录音也可以播
 AVAudioSessionCategoryAudioProcessing	硬件解码音频，此时不能播放和录制
 AVAudioSessionCategoryMultiRoute	多种输入输出，例如可以耳机、USB设备同时播放
 */

#import "ViewController.h"
#define KScreenWidth [UIScreen mainScreen].bounds.size.width
#define KScreenHeight [UIScreen mainScreen].bounds.size.height
@interface ViewController ()
@property(nonatomic,assign)BOOL isPlaying;
@property(nonatomic,strong)AVAudioPlayer *player;   //只支持本地播放不支持网络加载
@property(nonatomic,strong)NSTimer *timer;
@property(nonatomic,strong)UIProgressView *progress;
@property(nonatomic,strong)UIButton *playBtn;
@property(nonatomic,strong)UISlider* volumeViewSlider;
@property(nonatomic,assign)float systemVolume;
@property(nonatomic,assign)CGPoint startPoint;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUI];
    [self findSystemVolumeSlider];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //开启远程控制   为了能够让应用退到后台之后支持耳机控制
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

-(void)findSystemVolumeSlider{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    self.volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            self.volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    self.systemVolume = self.volumeViewSlider.value;
}

-(void)setUI{
    self.title  =@"海阔天空";
    UIImageView *imageView = [[UIImageView  alloc] initWithFrame:self.view.frame];
    imageView.image = [UIImage imageNamed:@"timg.jpg"];
    [self.view addSubview:imageView];
    ////UI懒得布局随便写的,请只看知识点就ok
    UIView *blavkView = [[UIView alloc] initWithFrame:CGRectMake(0, KScreenHeight - 128, KScreenWidth, 128)];
    blavkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    [self.view addSubview: blavkView];
    UILabel *singerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 70, 30)];
    singerLabel.textColor = [UIColor redColor];
    singerLabel.font = [UIFont systemFontOfSize:14];
    singerLabel.text = @"Beyond";
    singerLabel.textAlignment = NSTextAlignmentCenter;
    [blavkView addSubview:singerLabel];
    
    UIButton *downBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [downBtn setTitle:@"下载" forState:UIControlStateNormal];
    [downBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    downBtn.frame = CGRectMake(KScreenWidth - 130, 10, 60, 30);
    downBtn.backgroundColor = [UIColor lightGrayColor];
    [blavkView addSubview:downBtn];
    
    UIButton *starBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [starBtn setTitle:@"收藏" forState:UIControlStateNormal];
    starBtn.frame = CGRectMake(KScreenWidth - 60, 10, 60, 30);
    starBtn.backgroundColor = [UIColor lightGrayColor];
    [blavkView addSubview:starBtn];
    
    self.progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progress.progressTintColor = [UIColor blueColor];
    self.progress.trackTintColor = [UIColor whiteColor];
    self.progress.frame = CGRectMake(0, starBtn.frame.origin.y + 35, KScreenWidth, 10);
    [blavkView addSubview:self.progress];
    
    UIButton *preBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [preBtn setTitle:@"<<" forState:UIControlStateNormal];
    [preBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    preBtn.frame = CGRectMake(KScreenWidth/3 - (50/2) , self.progress.frame.origin.y + 10 +10, 50, 50);
    preBtn.backgroundColor = [UIColor lightGrayColor];
    [blavkView addSubview:preBtn];
    [preBtn addTarget:self action:@selector(preClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.playBtn setTitle:@"播放" forState:UIControlStateNormal];
    [self.playBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.playBtn.frame = CGRectMake(KScreenWidth/2 - 25 , self.progress.frame.origin.y + 10 +10, 50, 50);
    self.playBtn.backgroundColor = [UIColor lightGrayColor];
    [blavkView addSubview:self.playBtn];
    [self.playBtn addTarget:self action:@selector(playClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [nextBtn setTitle:@">>" forState:UIControlStateNormal];
    [nextBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    nextBtn.frame = CGRectMake(KScreenWidth  - (KScreenWidth/3 + (50/2)) , self.progress.frame.origin.y + 10 +10, 50, 50);
    nextBtn.backgroundColor = [UIColor lightGrayColor];
    [blavkView addSubview:nextBtn];
    [nextBtn addTarget:self action:@selector(nextClick:) forControlEvents:UIControlEventTouchUpInside];
    
}

-(void)preClick:(UIButton *)btn{
    NSLog(@"上一首");
}

-(void)playClick:(UIButton *)btn{
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(upDataprogress) userInfo:nil repeats:YES];
    }
    if (!self.isPlaying) {
        [btn setTitle:@"暂停" forState:UIControlStateNormal];
        [self play];
    }else{
        [btn setTitle:@"播放" forState:UIControlStateNormal];
        [self pause];
    }
    self.isPlaying = !self.isPlaying;
    NSLog(@"播放");
}

-(void)nextClick:(UIButton *)btn{
    NSLog(@"下一首");
}

-(void)pause{
    if ([self.player isPlaying]) {
        [self.player pause];
        self.timer.fireDate = [NSDate distantFuture];//定时器暂停,不要废除定时器否则无法恢复
        [self.playBtn setTitle:@"播放" forState:UIControlStateNormal];
    }
}

-(void)play{
    self.timer.fireDate = [NSDate distantPast]; //恢复定时器
    if (!self.player) {
        self.player = [self createMusicPlayer];
        [self.player play];
    }else{
        [self.player play];
    }
    [self.playBtn setTitle:@"暂停" forState:UIControlStateNormal];
}

-(void)upDataprogress{
    float progressValue = self.player.currentTime/self.player.duration;
    [self.progress setProgress:progressValue animated:YES];
}

-(AVAudioPlayer *)createMusicPlayer{
    NSString *urlStr = [[NSBundle mainBundle] pathForResource:@"海阔天空.mp3" ofType:nil];
    NSURL *url = [NSURL fileURLWithPath:urlStr];
    AVAudioPlayer * musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    musicPlayer.numberOfLoops = 0;
    musicPlayer.delegate = self;
    musicPlayer.volume = 3;
    [musicPlayer prepareToPlay];
    //立体声平衡，如果为-1.0则完全左声道，如果0.0则左右声道平衡，如果为1.0则完全为右声道
    musicPlayer.pan = 0.0;
    
    [self configurationBacgroundMode];
    [self configurationHeadset];
    return musicPlayer;
}

-(void)configurationBacgroundMode{
    //设置后台播放模式
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    //        [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];
    [audioSession setActive:YES error:nil];
}

-(void)configurationHeadset{
    //添加通知,拔出耳机后暂停播放
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [self.timer invalidate];
    self.timer = nil;
    NSLog(@"播放完成,调用下一首的方法");
}
//接受远程事件,
/*
 ios事件分为三类:
 1.触摸事件:通过触摸,手势进行触发(例如手指点击,缩放);
 2.运动事件:通过加速器进行触发(例如手机晃动)
 3.远程控制事件:通过其他远程设备触发(例如耳机控制按钮);
 */
-(void)remoteControlReceivedWithEvent:(UIEvent *)event{
    if (event.type == UIEventTypeRemoteControl) {
        switch (event.subtype ) {
            //播放或暂停切换【操作：播放或暂停状态下，按耳机线控中间按钮一下】
            case UIEventSubtypeRemoteControlTogglePlayPause:{
                if (![self.player isPlaying]) {
                    [self play];
                }else{
                    [self pause];
                }
                
            }
            case UIEventSubtypeNone:{
                NSLog(@"不包含任何子事件");
            }
                break;
            case UIEventSubtypeMotionShake:{
                NSLog(@"摇晃事件(ios3.0开始支持)");
            }
                break;
            case UIEventSubtypeRemoteControlPlay:{
                NSLog(@"播放事件[操作:停止状态下按耳机中间键一下]");
            }
            case UIEventSubtypeRemoteControlPause :
            {
                NSLog(@"停止事件");
            }
                break;
            case UIEventSubtypeRemoteControlStop:{
                NSLog(@"停止事件");
            }
                break;
            default:
                break;
        }
    }
}
/*
 typedef NS_ENUM(NSInteger, UIEventSubtype) {
 // 不包含任何子事件类型
 UIEventSubtypeNone                              = 0,
 
 // 摇晃事件（从iOS3.0开始支持此事件）
 UIEventSubtypeMotionShake                       = 1,
 
 //远程控制子事件类型（从iOS4.0开始支持远程控制事件）
 //播放事件【操作：停止状态下，按耳机线控中间按钮一下】
 UIEventSubtypeRemoteControlPlay                 = 100,
 //暂停事件
 UIEventSubtypeRemoteControlPause                = 101,
 //停止事件
 UIEventSubtypeRemoteControlStop                 = 102,
 //播放或暂停切换【操作：播放或暂停状态下，按耳机线控中间按钮一下】
 UIEventSubtypeRemoteControlTogglePlayPause      = 103,
 //下一曲【操作：按耳机线控中间按钮两下】
 UIEventSubtypeRemoteControlNextTrack            = 104,
 //上一曲【操作：按耳机线控中间按钮三下】
 UIEventSubtypeRemoteControlPreviousTrack        = 105,
 //快退开始【操作：按耳机线控中间按钮三下不要松开】
 UIEventSubtypeRemoteControlBeginSeekingBackward = 106,
 //快退停止【操作：按耳机线控中间按钮三下到了快退的位置松开】
 UIEventSubtypeRemoteControlEndSeekingBackward   = 107,
 //快进开始【操作：按耳机线控中间按钮两下不要松开】
 UIEventSubtypeRemoteControlBeginSeekingForward  = 108,
 //快进停止【操作：按耳机线控中间按钮两下到了快进的位置松开】
 UIEventSubtypeRemoteControlEndSeekingForward    = 109,
 };
 */
-(void)routeChange:(NSNotification *)notification{
    NSDictionary *dic = notification.userInfo;
    int changeReason = [[dic objectForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    //如果旧输出不可用
    if (changeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription = dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescripation = [routeDescription.outputs firstObject];
        if ([portDescripation.portType isEqualToString:@"Headphones"]) {
            [self pause];
        }
    }
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if(event.allTouches.count == 1){
        //保存当前触摸的位置
        CGPoint point = [[touches anyObject] locationInView:self.view];
        self.startPoint = point;
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if(event.allTouches.count == 1){
        //计算位移
        CGPoint point = [[touches anyObject] locationInView:self.view];
        //        float dx = point.x - startPoint.x;
        float dy = point.y - self.startPoint.y;
        int index = (int)dy;
        if(index>0){
            if(index%5==0){//每10个像素声音减一格
                NSLog(@"%.2f",self.systemVolume);
                if(self.systemVolume>0.1){
                    self.systemVolume = self.systemVolume-0.05;
                    [self.volumeViewSlider setValue:self.systemVolume animated:YES];
                    [self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
                }
            }
        }else{
            if(index%5==0){//每10个像素声音增加一格
                NSLog(@"+x ==%d",index);
                NSLog(@"%.2f",self.systemVolume);
                if(self.systemVolume>=0 && self.systemVolume<1){
                    self.systemVolume = self.systemVolume+0.05;
                    [self.volumeViewSlider setValue:self.systemVolume animated:YES];
                    [self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
                }
            }
        }
        //亮度调节
        //        [UIScreen mainScreen].brightness = (float) dx/self.view.bounds.size.width;
    }
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[AVAudioSession sharedInstance]setActive:NO error:nil];
    // Dispose of any resources that can be recreated.
}

@end
