//
//  MMCamera.h
//  MMArgoraBeautyKitDemo
//
//  Created by sunfei on 2020/11/24.
//  Copyright © 2020 sunfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MMAgoraCamera;

@protocol MMAgoraCameraDelegate <NSObject>

- (void)camera:(MMAgoraCamera *)camera didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp;

@end

@interface MMAgoraCamera : NSObject
@property (nonatomic, assign) AVCaptureDevicePosition position;
- (void)switchCamera;
- (void)startCapture;
- (void)stopCapture;


@property (nonatomic, weak) id<MMAgoraCameraDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
