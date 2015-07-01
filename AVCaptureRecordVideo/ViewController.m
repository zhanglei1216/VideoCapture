//
//  ViewController.m
//  AVCaptureRecordVideo
//
//  Created by foreveross－bj on 15/6/30.
//  Copyright (c) 2015年 foreveross－bj. All rights reserved.
//

#import "ViewController.h"
#import "VideoCapture.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()

@property (nonatomic, strong) VideoCapture *videoCapture;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) UIView *bView;
@property (nonatomic, strong) NSString *filePath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIView *aview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 240)];
    [self.view addSubview:aview];
    
    _bView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 200) / 2,self.view.frame.size.height - self.view.frame.size.width / 2 - 100, 200, self.view.frame.size.width)];
    [self.view addSubview:_bView];
    _bView.backgroundColor = [UIColor blackColor];
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        _filePath = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", @"mov"]];

    self.videoCapture = [[VideoCapture alloc] initWithView:aview filePath:_filePath];
    
    self.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:_filePath]];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    playerLayer.frame = CGRectMake(0, 0, 200, self.view.frame.size.width);
    [_bView.layer addSublayer:playerLayer];
    _bView.transform = CGAffineTransformMakeRotation(M_PI_2);
}
- (IBAction)start:(id)sender {
    [_videoCapture startVideoCapture];
}
- (IBAction)stop:(id)sender {
    [_videoCapture stopVideoCapture];
}
- (IBAction)play:(id)sender {
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:_filePath]];
    [_player replaceCurrentItemWithPlayerItem:playerItem];
    [_player play];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
