//
//  BBCamera.m
//  BiBi
//
//  Created by YuAo on 3/29/16.
//  Copyright © 2016 wemomo.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDRecordCamera.h"

static NSArray *compatibleDimensionsForSessionPreset(AVCaptureSessionPreset sessionPreset) {
    if ([sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
        return @[[NSValue valueWithCGSize:CGSizeMake(480, 640)]];
    } else if ([sessionPreset isEqualToString:AVCaptureSessionPresetiFrame960x540]) {
        return @[[NSValue valueWithCGSize:CGSizeMake(540, 960)]];
    } else if ([sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        return @[[NSValue valueWithCGSize:CGSizeMake(720, 1280)]];
    } else {
        return @[[NSValue valueWithCGSize:CGSizeMake(1080, 1920)], [NSValue valueWithCGSize:CGSizeMake(720, 1280)]];
    }
}

static AVCaptureVideoOrientation DeviceOrientation2captureVideoOrientation(UIDeviceOrientation orientation) {
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIDeviceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIDeviceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        case UIDeviceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        default:
            return AVCaptureVideoOrientationPortrait;
    }
}

static CGFloat scoreForVideoFormat(AVCaptureDeviceFormat *format, NSArray *compatableDimensions) {
    CMVideoFormatDescriptionRef formatDescription = format.formatDescription;
    CMVideoDimensions videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
    BOOL fullRangeVideoFormat = (CMFormatDescriptionGetMediaSubType(formatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
    CMVideoDimensions hrsiDimension = format.highResolutionStillImageDimensions;
    BOOL binned = format.isVideoBinned;
    CGFloat score = 0.0f;
    
    CMVideoDimensions preferredVideoDimensions = (CMVideoDimensions) {
        .width = 0,
        .height = 0
    };
    BOOL foundPreferredVideoDimensions = NO;
    
    for (int i = 0; i < compatableDimensions.count; ++ i) {
        CGSize size = [compatableDimensions[i] CGSizeValue];
        CMVideoDimensions preferredDimensions = (CMVideoDimensions) {
            .width = (int32_t)size.width,
            .height = (int32_t)size.height
        };
        if ((videoDimensions.width == preferredDimensions.width && videoDimensions.height == preferredDimensions.height) ||
            (videoDimensions.height == preferredDimensions.width && videoDimensions.width == preferredDimensions.height)) {
            score += (20.0 - i);
            preferredVideoDimensions = videoDimensions;
            foundPreferredVideoDimensions = YES;
        }
    }
    
    if (!foundPreferredVideoDimensions) {
        return 0;
    }
    
    if (MIN(hrsiDimension.width, hrsiDimension.height) > MIN(preferredVideoDimensions.width, preferredVideoDimensions.height)) {
        score += 5;
    }
    
    if (fullRangeVideoFormat) {
        score += 2;
    }
    
    if (!binned) {
        score += 1;
    }
    
    return score;
}



@implementation MDRecordCameraConfiguration

@end

@implementation MDRCapturePhoto

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer metadata:(NSDictionary *)metadata timestamp:(CMTime)timestamp orientation:(int)orientation {
    if (self) {
        _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
        _metadata = metadata.copy;
        _imageOrientation = orientation;
        _timestamp = timestamp;
    }
    return self;
}

+ (instancetype)photoWithCapturePhoto:(AVCapturePhoto *)photo API_AVAILABLE(ios(11.0)) {
    CVPixelBufferRef pixelBuffer = photo.pixelBuffer;
    NSDictionary *metadata = photo.metadata[(__bridge NSString *)kCGImagePropertyExifDictionary];
    CGImagePropertyOrientation imageOrientation = [photo.metadata[(__bridge NSString *)kCGImagePropertyOrientation] intValue];
    CMTime timestamp = photo.timestamp;
    return [[self alloc] initWithPixelBuffer:pixelBuffer metadata:metadata timestamp:timestamp orientation:imageOrientation];
}

+ (instancetype)photoWithSampleBuffer:(CMSampleBufferRef)photoSampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(photoSampleBuffer);
    CFDictionaryRef exifAttachments = CMGetAttachment(photoSampleBuffer, kCGImagePropertyExifDictionary, NULL);
    NSDictionary *metaInfo = [(__bridge NSDictionary*)exifAttachments copy];
    NSNumber *orientation = CMGetAttachment(photoSampleBuffer, kCGImagePropertyOrientation, NULL);
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(photoSampleBuffer);
    return [[self alloc] initWithPixelBuffer:pixelBuffer metadata:metaInfo timestamp:timestamp orientation:[orientation intValue]];
}

- (void)dealloc {
    CVPixelBufferRelease(self.pixelBuffer);
}

@end

@interface MDRecordCamera ()
<
AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate,
AVCapturePhotoCaptureDelegate,
AVCaptureMetadataOutputObjectsDelegate
>

@property (nonatomic, strong) MDRecordCameraConfiguration *configuration;

@property (nonatomic, strong) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;

@property (nonatomic, strong) AVCaptureSession *captureSession;

// video device & input
@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;

// video data output & connection
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;

// photo output & connection
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, readonly) AVCaptureConnection *photoConnection;
@property (nonatomic, copy) void(^photoCompletion)(MDRCapturePhoto * _Nullable, NSError * _Nullable);
@property (nonatomic, copy) void(^photoWillCaptureHandler)(void);

// audio device input &
@property (nonatomic, strong) AVCaptureDeviceInput *audioDeviceInput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, readonly) AVCaptureConnection *audioConnection;
@property (nonatomic, strong) dispatch_queue_t audioDataOutputQueue;

@property (nonatomic, strong) AVCaptureMetadataOutput *metaDataOutput;

@end

@implementation MDRecordCamera

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.audioDataOutput setSampleBufferDelegate:nil queue:nil];
    [self.videoDataOutput setSampleBufferDelegate:nil queue:nil];
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}

- (id)initWithConfiguration:(MDRecordCameraConfiguration *)configuration {
    if (self = [super init]) {
        
        _configuration = configuration;
        
        _captureSession = [[AVCaptureSession alloc] init];

        _videoDataOutputQueue = dispatch_queue_create("com.immomo.record.capture.video", NULL);
        _audioDataOutputQueue = dispatch_queue_create("com.immomo.record.capture.audio", NULL);
        NSArray<AVCaptureDeviceType> *deviceTypes = nil;
        if (@available(iOS 11.1, *)) {
            deviceTypes = @[AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera];
        } else if (@available(iOS 10.2, *)) {
            deviceTypes = @[AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera];
        } else {
            deviceTypes = @[AVCaptureDeviceTypeBuiltInDuoCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera];
        }
        
        _videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes
                                                                                              mediaType:AVMediaTypeVideo
                                                                                               position:AVCaptureDevicePositionUnspecified];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionDidStartRunning:) name:AVCaptureSessionDidStartRunningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionDidStopRunning:) name:AVCaptureSessionDidStopRunningNotification object:nil];
    }
    return self;
}

- (void)configureSession {
    [self.captureSession beginConfiguration];
    
    if ([self.captureSession canSetSessionPreset:self.configuration.sessionPreset]) {
        self.captureSession.sessionPreset = self.configuration.sessionPreset;
    }

    if (!self.videoDevice) {
        [self usesVideoCaptureDeviceInPosition:self.configuration.position];
        [self activeVideoDataOutput];
        [self activeMetaDataOupPut];
        [self activePhotoOutput];
    }
    
    [self pickActiveFormat:^CGFloat(AVCaptureDeviceFormat *format) {
        return scoreForVideoFormat(format, compatibleDimensionsForSessionPreset(self.configuration.sessionPreset));
    }];
    
    [self configVideoConnection];
    
    if (self.configuration.disableAutoConfigAudioSession && self.captureSession.automaticallyConfiguresApplicationAudioSession) {
        self.captureSession.automaticallyConfiguresApplicationAudioSession = NO;
    }
    
    [self.captureSession commitConfiguration];
    
    if (!self.captureSession.automaticallyConfiguresApplicationAudioSession && ![[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDuckOthers|AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP error:nil];
    }
}

- (void)configVideoConnection {
    if (self.videoConnection) {
        if ([self.videoConnection isVideoMirroringSupported]) {
            self.videoConnection.videoMirrored = NO;
        }
        
        if ([self.videoConnection isVideoOrientationSupported]) {
            self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
        if ([self.videoConnection isVideoStabilizationSupported]) {
            if ([self.videoDevice.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeStandard]) {
                self.videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeStandard;
            } else {
                self.videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
            }
        }
    }
}

- (void)usesVideoCaptureDeviceInPosition:(AVCaptureDevicePosition)preferredPosition {
    
    AVCaptureDeviceType preferredDeviceType = nil;
    switch (preferredPosition) {
        case AVCaptureDevicePositionBack:
            if (@available(iOS 10.2, *)) {
                preferredDeviceType = AVCaptureDeviceTypeBuiltInDualCamera;
            } else {
                preferredDeviceType = AVCaptureDeviceTypeBuiltInDuoCamera;
            }
            break;
            
        case AVCaptureDevicePositionUnspecified:
            preferredPosition = AVCaptureDevicePositionFront;
            // pass through
        case AVCaptureDevicePositionFront:
            if (@available(iOS 11.1, *)) {
                preferredDeviceType = AVCaptureDeviceTypeBuiltInTrueDepthCamera;
            } else {
                preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
            }
            break;
            
        default:
            break;
    }
    
    AVCaptureDevice *device = [self videoDeviceWithPosition:preferredPosition preferredDeviceType:preferredDeviceType];
    
    NSError *deviceError = nil;
    if ([device lockForConfiguration:&deviceError]) {
        
        if ([device isSmoothAutoFocusSupported]) {
            device.smoothAutoFocusEnabled = YES;
        }
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        if ([self supportCaptureFlashMode:AVCaptureFlashModeOff]) {
            self.flashMode = AVCaptureFlashModeOff;
        }
        if ([device isLowLightBoostSupported]) {
            device.automaticallyEnablesLowLightBoostWhenAvailable = YES;
        }
        if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        }
        if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            device.automaticallyAdjustsVideoHDREnabled = YES;
        }
        [device setExposureTargetBias:-0.8 completionHandler:nil];
        [device unlockForConfiguration];
    } else {
//        [MDRCameraException reportWarningWithCode:MDRCameraWarningCode_CameraDeviceConfigureFail warningInfo:deviceError.description uploadService:YES];
        NSLog(@"camera error");
    }
    self.videoDevice = device;
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
//        [MDRCameraException reportError:error errorCode:MDRCameraErrorCode_CameraDeviceNotWorking];
        NSLog(@"camera error");
    } else {
        if (self.videoDeviceInput) {
            [self.captureSession removeInput:self.videoDeviceInput];
        }
        if([self.captureSession canAddInput:videoInput]){
            [self.captureSession addInput:videoInput];
            self.videoDeviceInput = videoInput;
        }
    }
}

- (AVCaptureConnection *)videoConnection {
    
    return [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
}

- (AVCaptureConnection *)photoConnection {
    return [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
}

- (AVCaptureConnection *)audioConnection {
    return [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
}

- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position preferredDeviceType:(AVCaptureDeviceType)deviceType {
    NSArray<AVCaptureDevice *> *devices = self.videoDeviceDiscoverySession.devices;
    
    AVCaptureDevice *prefferedVideoDevice = nil;
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            if ([device.deviceType isEqualToString:deviceType]) {
                prefferedVideoDevice = device;
                break;
            } else if (!prefferedVideoDevice) {
                prefferedVideoDevice = device;
            }
        }
    }
    return prefferedVideoDevice;
}

- (void)activeVideoDataOutput {
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    if ([self.captureSession canAddOutput:videoOutput]) {
        [self.captureSession addOutput:videoOutput];
        [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
        [videoOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
        [videoOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
        
        
    }
    
    self.videoDataOutput = videoOutput;
    
}

- (void)activeMetaDataOupPut{
    _metaDataOutput = [[AVCaptureMetadataOutput alloc] init];
    if ([_captureSession canAddOutput:_metaDataOutput]) {
        [_captureSession addOutput:_metaDataOutput];
        
        NSArray<AVMetadataObjectType>* mataObjects = [_metaDataOutput availableMetadataObjectTypes];
        if([mataObjects containsObject:AVMetadataObjectTypeFace])
        {
            //指定对象输出的元数据类型，AV Foundation支持多种类型 这里限制使用人脸元数据
            NSArray *metadataObjectTypes = @[AVMetadataObjectTypeFace];
            _metaDataOutput.metadataObjectTypes = metadataObjectTypes;
            
            //人脸检测用到的硬件加速，而且许多重要的任务都在主线程，一般指定主线程
            dispatch_queue_t mainQueue = dispatch_get_main_queue();
            //指定AVCaptureMetadataOutputObjectsDelegate
            [_metaDataOutput setMetadataObjectsDelegate:self  queue:mainQueue];
        }
    }
}

- (void)activePhotoOutput {
    AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([self.captureSession canAddOutput:photoOutput]) {
        [self.captureSession addOutput:photoOutput];
        
        photoOutput.highResolutionCaptureEnabled = YES;
        photoOutput.livePhotoCaptureEnabled = NO;
    }
    self.photoOutput = photoOutput;
}

- (void)activeAudioDataOutput {
    [self.captureSession beginConfiguration];
    if (!self.audioDeviceInput) {
        NSError *error;
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error];
        if (!error) {
            if ([self.captureSession canAddInput:audioInput]) {
                [self.captureSession addInput:audioInput];
                self.audioDeviceInput = audioInput;
            }
        } else {
//			[MDRCameraException reportWarningWithCode:MDRCameraWarningCode_CameraDeviceConfigureFail
//										  warningInfo:error.description
//										uploadService:YES];
            NSLog(@"camera error");
        }
    }
    
    if (!self.audioDataOutput) {
        AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [audioOutput setSampleBufferDelegate:self queue:self.audioDataOutputQueue];
        if ([self.captureSession canAddOutput:audioOutput]) {
            [self.captureSession addOutput:audioOutput];
            self.audioDataOutput = audioOutput;
        }
    }
    [self.captureSession commitConfiguration];
}

- (void)disableAudioDataOutput {
    [self.captureSession beginConfiguration];
    if (self.audioDataOutput) {
        [self.captureSession removeOutput:self.audioDataOutput];
        self.audioDataOutput = nil;
    }
    
    if (self.audioDeviceInput) {
        [self.captureSession removeInput:self.audioDeviceInput];
        self.audioDeviceInput = nil;
    }
    [self.captureSession commitConfiguration];
}

- (void)pickActiveFormat:(CGFloat(^)(AVCaptureDeviceFormat *))scoreFunction {
    if (!self.videoDevice) {
        return;
    }
    
    AVCaptureDeviceFormat *bestFormat = [self.videoDevice.formats sortedArrayUsingComparator:^NSComparisonResult(AVCaptureDeviceFormat *obj1, AVCaptureDeviceFormat *obj2) {
        CGFloat score1 = scoreFunction(obj1);
        CGFloat score2 = scoreFunction(obj2);
        if (score1 < score2) {
            return NSOrderedAscending;
        } else if (score1 > score2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }].lastObject;
    
    AVFrameRateRange *frameRateRange = bestFormat.videoSupportedFrameRateRanges.firstObject;
    
    if (!frameRateRange) {
        return;
    }
    
    CMTimeScale minFrameRate = (CMTimeScale)MAX(frameRateRange.minFrameRate, (Float64)self.videoCaptureDeviceFrameRate);
    CMTimeScale maxFrameRate = (CMTimeScale)MIN(frameRateRange.maxFrameRate, (Float64)self.videoCaptureDeviceFrameRate);
    
    NSError *error = nil;
    if ([self.videoDevice lockForConfiguration:&error]) {
        self.videoDevice.activeFormat = bestFormat;
        self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, maxFrameRate);
        self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, minFrameRate);
        [self.videoDevice unlockForConfiguration];
    } else {
//        [MDRCameraException reportWarningWithCode:MDRCameraWarningCode_CameraDeviceConfigureFail
//                                      warningInfo:error.description
//                                    uploadService:YES];
        NSLog(@"camera error");
    }
}

- (void)startRunningWithConfiguration:(MDRecordCameraConfiguration *)configuration {
    
    if (self.captureSession.isRunning) {
        return;
    }
    
    if (configuration) {
        self.configuration = configuration;
    }
    
    [self configureSession];
    
    [self.captureSession startRunning];
}

- (void)stopRunning {
    if (!self.captureSession.isRunning) {
        return;
    }
    
    [self.captureSession stopRunning];
}

- (float)minExposureTargetBias {
    if (self.videoDevice) {
        return MAX(self.videoDevice.minExposureTargetBias, [self minBias]);
    } else {
        return [self minBias];
    }
}

- (float)maxExposureTargetBias {
    if (self.videoDevice) {
        return MIN(self.videoDevice.maxExposureTargetBias, [self maxBias]);
    } else {
        return [self maxBias];
    }
}

- (void)rotateCamera {
    
    if (!self.videoDevice) {
        return;
    }
    [self.captureSession beginConfiguration];
    
    AVCaptureDevicePosition currentCameraPosition = self.videoDevice.position;
    if (currentCameraPosition == AVCaptureDevicePositionBack) {
        [self usesVideoCaptureDeviceInPosition:AVCaptureDevicePositionFront];
    } else {
        [self usesVideoCaptureDeviceInPosition:AVCaptureDevicePositionBack];
    }
    [self.captureSession commitConfiguration];
}

- (void)focusAndExposeAtPoint:(CGPoint)pointOfInterest {
    
    if (!self.videoDevice) {
        return;
    }
    
    NSError *error;
    if ([self.videoDevice lockForConfiguration:&error]) {
        
        if ([self.videoDevice isExposurePointOfInterestSupported]) {
            self.videoDevice.exposurePointOfInterest = pointOfInterest;
            if ([self.videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                self.videoDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            } else if ([self.videoDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
                self.videoDevice.exposureMode = AVCaptureExposureModeAutoExpose;
            }
        }
        
        if (self.videoDevice.isFocusPointOfInterestSupported) {
            if (self.videoDevice.isSmoothAutoFocusSupported) {
                self.videoDevice.smoothAutoFocusEnabled = NO;
            }
            self.videoDevice.focusPointOfInterest = pointOfInterest;
            if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                self.videoDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            } else if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                self.videoDevice.focusMode = AVCaptureFocusModeAutoFocus;
            }
        }
        
        [self.videoDevice unlockForConfiguration];
    } else {
//        [MDRCameraException reportWarningWithCode:MDRCameraWarningCode_CameraDeviceConfigureFail
//                                      warningInfo:error.description
//                                    uploadService:YES];
        NSLog(@"camera error");
    }
}

- (void)updateExposureTargetBias:(float)bias {
    
    if (!self.videoDevice) {
        return;
    }
    
    if (self.videoDevice.exposureTargetBias != bias) {
        return;
    }
    
    CGFloat minBias = self.videoDevice.minExposureTargetBias;
    CGFloat maxBias = self.videoDevice.maxExposureTargetBias;
    
    bias = MIN(bias, maxBias);
    bias = MAX(bias, minBias);
    
    NSError *error = nil;
    if ([self.videoDevice lockForConfiguration:&error]) {
        [self.videoDevice setExposureTargetBias:bias completionHandler:nil];
        [self.videoDevice unlockForConfiguration];
    } else {
//        [MDRCameraException reportWarningWithCode:MDRCameraWarningCode_CameraDeviceConfigureFail
//                                      warningInfo:error.description
//                                    uploadService:YES];
        NSLog(@"camera error");
    }
}

- (void)setCameraZoomFactor:(float)zoomFactor {
    
    if (!self.videoDevice) {
        return;
    }
    
    NSError *error = nil;
    
    if ([self.videoDevice lockForConfiguration:&error]) {
        CGFloat maxScale = 6;
        if (@available(iOS 11.0, *)) {
            maxScale = self.videoDevice.maxAvailableVideoZoomFactor;
        }
        [self.videoDevice setVideoZoomFactor:MAX(MIN(zoomFactor, maxScale), 1)];
        [self.videoDevice unlockForConfiguration];
    } else {
//        [MDRCameraException reportWarningWithCode:MDRCameraWarningCode_CameraDeviceConfigureFail
//                                      warningInfo:error.description
//                                    uploadService:YES];
        NSLog(@"camera error");
    }
}

- (float)cameraZoomFactor {
    return self.videoDevice.videoZoomFactor;
}

- (void)restoreZoomFactor {
    [self setCameraZoomFactor:1.0];
}

- (void)cleanCamera {
    //remove input/output
    [self.captureSession beginConfiguration];
    if (self.videoDataOutput) {
        [self.captureSession removeOutput:self.videoDataOutput];
        self.videoDataOutput = nil;
    }
    
    if (self.audioDataOutput) {
        [self.captureSession removeOutput:self.audioDataOutput];
        self.audioDataOutput = nil;
    }
    
    if (self.photoOutput) {
        [self.captureSession removeOutput:self.photoOutput];
        self.photoOutput = nil;
    }
    
    if (self.videoDeviceInput) {
        [self.captureSession removeInput:self.videoDeviceInput];
        self.videoDeviceInput = nil;
    }
    
    if (self.audioDeviceInput) {
        [self.captureSession removeInput:self.audioDeviceInput];
        self.audioDeviceInput = nil;
    }
    [self.captureSession commitConfiguration];
}

- (void)setVideoCaptureDeviceFrameRate:(NSInteger)videoCaptureDeviceFrameRate {
    _videoCaptureDeviceFrameRate = videoCaptureDeviceFrameRate;
    [self pickActiveFormat:^CGFloat(AVCaptureDeviceFormat *format) {
        return scoreForVideoFormat(format, compatibleDimensionsForSessionPreset(self.configuration.sessionPreset));
    }];
}

- (void)enableSmoothAutoFocus:(BOOL)enable {
    if (!self.videoDevice.isSmoothAutoFocusEnabled) {
        return;
    }
    
    NSError *error;
    if ([self.videoDevice lockForConfiguration:&error]) {
        [self.videoDevice setSmoothAutoFocusEnabled:enable];
        [self.videoDevice unlockForConfiguration];
	} else {
//		[MDRCameraException reportWarningWithCode:MDRCameraWarningCode_CameraDeviceConfigureFail
//									  warningInfo:error.description
//									uploadService:YES];
        NSLog(@"camera error");
	}
}

- (void)updateISO:(float)ISO {
    NSError *error = nil;
    if ([self.videoDevice lockForConfiguration:&error]) {
        [self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent
                                                                ISO:ISO
                                                  completionHandler:nil];
        [self.videoDevice unlockForConfiguration];
    } else {
//		[MDRCameraException reportWarningWithCode:MDRCameraWarningCode_CameraDeviceConfigureFail
//									  warningInfo:error.description
//									uploadService:YES];
        NSLog(@"camera error");
    }
}

- (AVCaptureDevicePosition)currentDevicePosition {
    return self.videoDevice.position;
}

- (BOOL)hasFlash {
    return [self.videoDevice hasFlash];
}

- (BOOL)hasTorch {
    return [self.videoDevice hasTorch];
}

- (BOOL)hasVideoInput {
    BOOL hasVideoInput = NO;
    for (AVCaptureInput *input in self.captureSession.inputs) {
        for (AVCaptureInputPort *port in input.ports) {
            if ([[port mediaType] isEqualToString:AVMediaTypeVideo]) {
                hasVideoInput = YES;
                break;
            }
        }
        if (hasVideoInput) {
            break;
        }
    }
    return hasVideoInput;
}

- (BOOL)supportCaptureFlashMode:(AVCaptureFlashMode)mode {
    return [self.photoOutput.supportedFlashModes containsObject:@(mode)];
}

- (BOOL)supportCpatureTorchMode:(AVCaptureTorchMode)mode {
    return [self.videoDevice isTorchModeSupported:mode];
}

- (void)setFlashMode:(AVCaptureFlashMode)mode {
    if (![self supportCaptureFlashMode:mode]) {
        return;
    }
    NSError *error;
    if ([self.videoDevice lockForConfiguration:&error]) {
        _flashMode = mode;
        [self.videoDevice unlockForConfiguration];
	} else {
//		[MDRCameraException reportWarningWithCode:MDRCameraWarningCode_CameraDeviceConfigureFail
//									  warningInfo:error.description
//									uploadService:YES];
        NSLog(@"camera error");
	}
}

- (void)setTorchMode:(AVCaptureTorchMode)mode {
    if (![self.videoDevice isTorchModeSupported:mode]) {
        return;
    }
    NSError *error;
    if ([self.videoDevice lockForConfiguration:&error]) {
        [self.videoDevice setTorchMode:mode];
        [self.videoDevice unlockForConfiguration];
	} else {
//		[MDRCameraException reportWarningWithCode:MDRCameraWarningCode_CameraDeviceConfigureFail
//									  warningInfo:error.description
//									uploadService:YES];
        NSLog(@"camera error");
	}
}

- (AVCaptureTorchMode)torchMode {
    return self.videoDevice.torchMode;
}

#pragma mark - photo output

- (void)capturePhotoWithOrientation:(UIDeviceOrientation)orientation
                    willBeginHander:(void(^)(void))handler
                         completion:(void(^)(MDRCapturePhoto *, NSError *))completion {
    if (!self.videoDevice) {
        NSError *error = [NSError errorWithDomain:@"camera" code:-1000 userInfo:@{NSLocalizedFailureReasonErrorKey:@"相机未初始化"}];
        !completion ?: completion(NULL, error);
        return;
    }
    
    if (!self.videoConnection || !self.videoConnection.isEnabled || !self.videoConnection.isActive) {
        NSError *error = [NSError errorWithDomain:@"camera" code:-1000 userInfo:@{NSLocalizedFailureReasonErrorKey:@"相机未初始化"}];
        !completion ?: completion(NULL, error);
        return;
    }
    
    if (!self.photoConnection || !self.photoConnection.isEnabled || !self.photoConnection.isActive) {
        NSError *error = [NSError errorWithDomain:@"camera" code:-1000 userInfo:@{NSLocalizedFailureReasonErrorKey:@"相机未初始化"}];
        !completion ?: completion(NULL, error);
        return;
    }
    
    if (self.photoConnection.isVideoOrientationSupported) {
        self.photoConnection.videoOrientation = DeviceOrientation2captureVideoOrientation(orientation);
    }
    if (self.photoConnection.isVideoMirroringSupported) {
        self.photoConnection.videoMirrored = (self.videoDevice.position == AVCaptureDevicePositionFront);
    }
    
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{
        (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
    }];
    
    if (self.videoDevice.isFlashAvailable) {
        photoSettings.flashMode = self.flashMode;
    }
    
    photoSettings.highResolutionPhotoEnabled = YES;
    
//    if (photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0) {
//        photoSettings.previewPhotoFormat = @{
//            (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject
//        };
//    }
    photoSettings.previewPhotoFormat = nil;
    
    photoSettings.autoStillImageStabilizationEnabled = YES;
    
    self.photoWillCaptureHandler = handler;
    self.photoCompletion = completion;
    
    [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self];
}

#pragma mark - AVCapturePhotoCaptureDelegate methods

- (void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    !self.photoWillCaptureHandler ?: self.photoWillCaptureHandler();
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error API_AVAILABLE(ios(11.0)) {
    if (error) {
        !self.photoCompletion ?: self.photoCompletion(nil, error);
    } else {
        MDRCapturePhoto *capturePhoto = [MDRCapturePhoto photoWithCapturePhoto:photo];
        !self.photoCompletion ?: self.photoCompletion(capturePhoto, nil);
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {
    if (photoSampleBuffer && !error) {
        MDRCapturePhoto *capturePhoto = [MDRCapturePhoto photoWithSampleBuffer:photoSampleBuffer];
        !self.photoCompletion ?: self.photoCompletion(capturePhoto, nil);
    } else {
        !self.photoCompletion ?: self.photoCompletion(nil, error);
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate methods

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [self.delegate recordCamera:self didOutputSampleBuffer:sampleBuffer];
}

- (void)captureOutput:(MDRecordCamera *)camera didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects{
    [self.delegate captureOutput:camera didOutputMetadataObjects:metadataObjects];
}

#pragma mark - Notification methods

- (void)captureSessionDidStartRunning:(NSNotification *)notification {
}

- (void)captureSessionDidStopRunning:(NSNotification *)notification {
}

- (CGFloat)maxBias {
    return 1.58;
}

- (CGFloat)minBias {
    return -1.38;
}

- (CGFloat)ratio {
    return [self maxBias] - [self minBias];
}


@end

