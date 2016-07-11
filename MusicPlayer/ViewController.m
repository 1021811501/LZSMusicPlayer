//
//  ViewController.m
//  MusicPlayer
//
//  Created by 李志帅 on 16/7/11.
//  Copyright © 2016年 李志帅. All rights reserved.

//菜鸟一个,不喜勿喷,欢迎大家关注我github,交流学习
//

#import "ViewController.h"
#define KScreenWidth [UIScreen mainScreen].bounds.size.width
#define KScreenHeight [UIScreen mainScreen].bounds.size.height
@interface ViewController ()
{
    UISlider* volumeViewSlider;
    float systemVolume;
    CGPoint startPoint;//起始位置
}
@property(nonatomic,assign)BOOL isPlaying;
@property(nonatomic,strong)AVAudioPlayer *player;   //只支持本地播放不支持网络加载
@property(nonatomic,strong)NSTimer *timer;
@property(nonatomic,strong)UIProgressView *progress;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title  =@"海阔天空";
    UIImageView *imageView = [[UIImageView  alloc] initWithFrame:self.view.frame];
    imageView.image = [UIImage imageNamed:@"timg.jpg"];
    [self.view addSubview:imageView];
    [self setUI];
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    systemVolume = volumeViewSlider.value;
    // Do any additional setup after loading the view, typically from a nib.
}
-(void)setUI{
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
    
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [playBtn setTitle:@"播放" forState:UIControlStateNormal];
    [playBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    playBtn.frame = CGRectMake(KScreenWidth/2 - 25 , self.progress.frame.origin.y + 10 +10, 50, 50);
    playBtn.backgroundColor = [UIColor lightGrayColor];
    [blavkView addSubview:playBtn];
    [playBtn addTarget:self action:@selector(playClick:) forControlEvents:UIControlEventTouchUpInside];
    
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
    musicPlayer.pan = -1;
    return musicPlayer;
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [self.timer invalidate];
    self.timer = nil;
    NSLog(@"播放完成,调用下一首的方法");
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if(event.allTouches.count == 1){
        //保存当前触摸的位置
        CGPoint point = [[touches anyObject] locationInView:self.view];
        startPoint = point;
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if(event.allTouches.count == 1){
        //计算位移
        CGPoint point = [[touches anyObject] locationInView:self.view];
        //        float dx = point.x - startPoint.x;
        float dy = point.y - startPoint.y;
        int index = (int)dy;
        if(index>0){
            if(index%5==0){//每10个像素声音减一格
                NSLog(@"%.2f",systemVolume);
                if(systemVolume>0.1){
                    systemVolume = systemVolume-0.05;
                    [volumeViewSlider setValue:systemVolume animated:YES];
                    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
                }
            }
        }else{
            if(index%5==0){//每10个像素声音增加一格
                NSLog(@"+x ==%d",index);
                NSLog(@"%.2f",systemVolume);
                if(systemVolume>=0 && systemVolume<1){
                    systemVolume = systemVolume+0.05;
                    [volumeViewSlider setValue:systemVolume animated:YES];
                    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
                }
            }
        }
        //亮度调节
        //        [UIScreen mainScreen].brightness = (float) dx/self.view.bounds.size.width;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
