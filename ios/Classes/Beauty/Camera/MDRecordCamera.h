//
//  BBCamera.h
//  BiBi
//
//  Created by YuAo on 3/29/16.
//  Copyright © 2016 wemomo.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class MDRecordCamera;

NS_ASSUME_NONNULL_BEGIN

@interface MDRecordCameraConfiguration : NSObject

@property (nonatomic, copy) AVCaptureSessionPreset _Nonnull sessionPreset;
@property (nonatomic, assign) AVCaptureDevicePosition position;
@property (nonatomic, assign) BOOL disableAutoConfigAudioSession;

@end

@interface MDRCapturePhoto : NSObject

@property (nonatomic, readonly) CVPixelBufferRef pixelBuffer;
@property (nonatomic, readonly) NSDictionary *metadata;
@property (nonatomic, readonly) CGImagePropertyOrientation imageOrientation;
@property (nonatomic, readonly) CMTime timestamp;

@end

@protocol MDRecordCameraDelegate <NSObject>

- (void)recordCamera:(MDRecordCamera *)camera didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)captureOutput:(MDRecordCamera *)camera didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects;
@end

@interface MDRecordCamera : NSObject

- (id)initWithConfiguration:(MDRecordCameraConfiguration *)configuration;

@property (nonatomic, weak) id<MDRecordCameraDelegate> delegate;

@property (nonatomic, readonly) AVCaptureDevice *videoDevice;
@property (nonatomic, readonly) AVCaptureConnection *videoConnection;

- (void)activeAudioDataOutput;
- (void)disableAudioDataOutput;

- (void)startRunningWithConfiguration:(MDRecordCameraConfiguration *)configuration;
- (void)stopRunning;

- (void)rotateCamera;

//camera的一些清理工作
- (void)cleanCamera;

@property (nonatomic) NSInteger videoCaptureDeviceFrameRate;

@property (nonatomic, readonly) AVCaptureDevicePosition currentDevicePosition;
@property (nonatomic, assign) float cameraZoomFactor;

@property (nonatomic, readonly) BOOL hasTorch;
@property (nonatomic, readonly) BOOL hasFlash;
@property (nonatomic, assign) AVCaptureTorchMode torchMode;
@property (nonatomic, assign) AVCaptureFlashMode flashMode;

@property (nonatomic,assign) BOOL disableAutoConfigAudioSession;

- (BOOL)supportCpatureTorchMode:(AVCaptureTorchMode)mode;
- (BOOL)supportCaptureFlashMode:(AVCaptureFlashMode)mode;

- (void)enableSmoothAutoFocus:(BOOL)enable;

@property (nonatomic, readonly) float minExposureTargetBias;
@property (nonatomic, readonly) float maxExposureTargetBias;

- (void)updateISO:(float)ISO;
- (void)updateExposureTargetBias:(float)bias;
- (void)focusAndExposeAtPoint:(CGPoint)pointOfInterest;

// take photo
- (void)capturePhotoWithOrientation:(UIDeviceOrientation)orientation
                    willBeginHander:(void(^ _Nullable)(void))handler
                         completion:(void(^ _Nonnull)(MDRCapturePhoto * _Nullable, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
