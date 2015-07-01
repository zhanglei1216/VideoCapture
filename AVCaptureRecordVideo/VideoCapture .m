//
//  RecordVideo.m
//  AVCaptureRecordVideo
//
//  Created by foreveross－bj on 15/6/30.
//  Copyright (c) 2015年 foreveross－bj. All rights reserved.
//

#import "VideoCapture.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoCapture ()<AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>{
    AVCaptureDevice *videoDevice;              //视频设备
    AVCaptureDevice *audioDevice;              //音频设备
    AVCaptureVideoDataOutput *videoOutput;     //视频输出
    AVCaptureAudioDataOutput *audioOutput;     //音频输出
    AVAssetWriterInput *videoWriterInput;      //视频写输入
    AVAssetWriterInput *audioWriterInput;      //音频写输入
    NSInteger frame;                           //总共的帧数

}

@property (nonatomic, strong) UIView *showView;                                 //显示录制画面的view
@property (nonatomic, strong) NSString *filePath;                               //视频保存路径
@property (nonatomic, strong) AVCaptureSession *captureSession;                 //视频扑捉会话
@property (nonatomic, strong) AVAssetWriter *videoWriter;                       //写视频文件操作
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;    //视频写输入适配器

@end


@implementation VideoCapture

/**
 * 初始化
 * @param 显示录制画面的view
 * @param 视频保存的路径
 */
- (id)initWithView:(UIView *)view filePath:(NSString *)filePath{
    self = [super init];
    if (self) {
        self.showView = view;
        self.filePath = filePath;
        _cameraType = VideoCameraBackType;
        _status = VideoNotCaptureStatus;
    }
    return self;
}

/**
 * 摄影机类型设置
 */
- (void)setCameraType:(VideoCameraType)cameraType{
    AVCaptureDevice *device = videoDevice;
    if ((videoDevice = [self cameraAtPosition:_cameraType ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront]) == nil) {
        NSLog(@"Failed to set capture device");
        videoDevice = device;
    }else {
        _cameraType = cameraType;
    }
}

/**
 * 开始显示录制画面
 */
- (void)startPreview{
    if(_captureSession && _showView && _status == VideoCaptureStartingStatus){
        AVCaptureVideoPreviewLayer* previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: _captureSession];
        previewLayer.frame = _showView.bounds;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [_showView.layer addSublayer: previewLayer];
        
        if(![_captureSession isRunning]){
            [_captureSession startRunning];
        }
    }
}
/**
 * 停止显示录制画面
 */
- (void)stopPreview{
    if(_captureSession){
        if([_captureSession isRunning]){
            [_captureSession stopRunning];
            
            // remove all sublayers
            if(_showView){
                for(CALayer *ly in _showView.layer.sublayers){
                    if([ly isKindOfClass: [AVCaptureVideoPreviewLayer class]])
                    {
                        [ly removeFromSuperlayer];
                        break;
                    }
                }
            }
        }
    }
}

/**
 * 获取输入设备
 * @param position
 */
- (AVCaptureDevice *)cameraAtPosition:(AVCaptureDevicePosition)position{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameras){
        if (device.position == position){
            return device;
        }
    }
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

/**
 * 开始录制视频
 */
- (void)startVideoCapture
{
    //防锁
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    
    
    //打开摄像设备，并开始捕抓图像
    if(videoDevice || audioDevice || _captureSession)
    {
        NSLog(@"Already capturing");
        return;
    }
    
    //初始化写操作
    [self initVideoAudioWriter];
    
    if((videoDevice = [self cameraAtPosition:_cameraType ?AVCaptureDevicePositionBack : AVCaptureDevicePositionFront]) == nil)
    {
        NSLog(@"Failed to get valide video capture device");
        return;
    }
    
    NSError *videoError = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&videoError];
    if (!videoInput)
    {
        NSLog(@"Failed to get video input");
        videoInput = nil;
        return;
    }
    
    if ((audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio]) == nil) {
        NSLog(@"Failed to get valide audio capture device");
        return;
    }
    
    NSError *audioError = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&audioError];
    if (!audioInput)
    {
        NSLog(@"Failed to get audio input");
        audioError = nil;
        return;
    }
    
    self.captureSession = [[AVCaptureSession alloc] init];
    
    [_captureSession beginConfiguration];
    
    _captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    [_captureSession addInput:videoInput];
    [_captureSession addInput:audioInput];

    videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    videoOutput.videoSettings = videoSettings;
    videoOutput.alwaysDiscardsLateVideoFrames = YES;
    dispatch_queue_t videoQueue = dispatch_queue_create("videoQueue", NULL);
    [videoOutput setSampleBufferDelegate:self queue:videoQueue];
    [_captureSession addOutput:videoOutput];
#if !OS_OBJECT_USE_OBJC
    dispatch_release(queue);
#endif
    
    
    audioOutput = [[AVCaptureAudioDataOutput alloc] init];
#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
   NSDictionary*  audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
                           
                           [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                           
                           [ NSNumber numberWithInt:64000], AVEncoderBitRateKey,
                           
                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                           
                           [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,nil];
    
    audioOutput.audioSettings = audioOutputSettings;
#endif
    
    [audioOutput setSampleBufferDelegate:self queue:videoQueue];
    [_captureSession addOutput:audioOutput];
    
    [_captureSession commitConfiguration];
    
    _status = VideoCaptureStartingStatus;
    //start preview
    [self startPreview];
}


/**
 * 停止录制视频
 */
- (void)stopVideoCapture{
    if(_captureSession){
        [_captureSession stopRunning];
        self.captureSession = nil;
        NSLog(@"Video capture stopped");
    }
    videoDevice = nil;
    audioDevice = nil;
    
    if(_showView){
        for (UIView *view in _showView.subviews) {
            [view removeFromSuperview];
        }
    }
    [_videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"%@", _videoWriter.error);
    }];
    _videoWriter = nil;
    _status = VideoNotCaptureStatus;
}


-(void) initVideoAudioWriter{
    frame = 0;
    
    CGSize size = CGSizeMake(640, 480);
    if (!_filePath) {
         self.filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    }
   
    NSError *error = nil;

    unlink([_filePath UTF8String]);
    
    //----initialize compression engine
    
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:_filePath]
                        
                                                 fileType:AVFileTypeQuickTimeMovie
                        
                                                    error:&error];
    
    
    NSParameterAssert(_videoWriter);
    
    if(error)
        
        NSLog(@"error = %@", [error localizedDescription]);
    
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           
                                           [NSNumber numberWithDouble:1024.0*1024.0],AVVideoAverageBitRateKey,
                                           
                                           nil ];
    
    
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   
                                   [NSNumber numberWithInt:size.height],AVVideoHeightKey,videoCompressionProps, AVVideoCompressionPropertiesKey, nil];
    
    videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    
    
    NSParameterAssert(videoWriterInput);
    
    
    
    videoWriterInput.expectsMediaDataInRealTime = YES;
    
    
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    
    
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                    
                                                                                   sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(videoWriterInput);
    
    NSParameterAssert([_videoWriter canAddInput:videoWriterInput]);
    
    
    
    if ([_videoWriter canAddInput:videoWriterInput])
        
        NSLog(@"I can add this input");
    
    else
        
        NSLog(@"i can't add this input");
    
    
    
    // Add the audio input
    
    AudioChannelLayout acl;
    
    bzero( &acl, sizeof(acl));
    
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
    
    
    NSDictionary* audioOutputSettings = nil;
    
    audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
                           
                           [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                           
                           [ NSNumber numberWithInt:64000], AVEncoderBitRateKey,
                           
                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                           
                           [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                           
                           [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                           
                           nil ];  
    
    audioWriterInput = [AVAssetWriterInput   
                         
                         assetWriterInputWithMediaType: AVMediaTypeAudio   
                         
                         outputSettings: audioOutputSettings ];

    audioWriterInput.expectsMediaDataInRealTime = YES;  
    NSParameterAssert(audioWriterInput);
    
    NSParameterAssert([_videoWriter canAddInput:audioWriterInput]);
    // add input  
    
    [_videoWriter addInput:audioWriterInput];
    
    [_videoWriter addInput:videoWriterInput];
    
}



#pragma mark audio or video date delegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    @autoreleasepool {
        CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        
        if(frame == 0 && _videoWriter.status != AVAssetWriterStatusWriting){
            
            [_videoWriter startWriting];
            
            [_videoWriter startSessionAtSourceTime:lastSampleTime];
            
        }
        
        if (captureOutput == videoOutput){
            if(_videoWriter.status > AVAssetWriterStatusWriting ){
                
                NSLog(@"Warning: writer status is %ld",(long)_videoWriter.status);
                
                if( _videoWriter.status == AVAssetWriterStatusFailed )
                    
                    NSLog(@"Error: %@", _videoWriter.error);
                
                return;
                
            }
            
            if ([videoWriterInput isReadyForMoreMediaData]){
                if( ![videoWriterInput appendSampleBuffer:sampleBuffer])
                    NSLog(@"Unable to write to video input");
                else
                    NSLog(@"already write vidio");
            }
            
        }else if (captureOutput == audioOutput){
            
            if(_videoWriter.status > AVAssetWriterStatusWriting){
                
                NSLog(@"Warning: writer status is %ld", (long)_videoWriter.status);
                
                if(_videoWriter.status == AVAssetWriterStatusFailed )
                    
                    NSLog(@"Error: %@", _videoWriter.error);
                
                return;
                
            }
            
            if ([audioWriterInput isReadyForMoreMediaData]){
                
                if( ![audioWriterInput appendSampleBuffer:sampleBuffer] )
                    NSLog(@"Unable to write to audio input");
                else
                    NSLog(@"already write audio");
            }
        }
        frame++;
    }
}

@end

