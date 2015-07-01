//
//  RecordVideo.h
//  AVCaptureRecordVideo
//
//  Created by foreveross－bj on 15/6/30.
//  Copyright (c) 2015年 foreveross－bj. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VideoCaptureStatus) {
    VideoNotCaptureStatus = 0,  //视频没有在录制
    VideoCaptureStartingStatus   //视频录制中
};

typedef NS_ENUM(NSInteger, VideoCameraType) {
    VideoCameraFrontType = 0,   //前摄像头
    VideoCameraBackType     //后摄像头
};

@interface VideoCapture : NSObject

@property (nonatomic, readonly) VideoCaptureStatus status; //录制状态

@property (nonatomic, assign) VideoCameraType cameraType; //照相机类型（前或后，默认是前）

/**
 * 初始化
 * @param 显示录制画面的view
 * @param 视频保存的路径
 */
- (id)initWithView:(UIView *)view filePath:(NSString *)filePath;

/**
 * 开始录制视频
 */
- (void)startVideoCapture;

/**
 * 停止录制视频
 */
- (void)stopVideoCapture;

@end
