//
//  MMArgoraSourceMediaIO.m
//  MMArgoraBeautyKitDemo
//
//  Created by sunfei on 2020/11/23.
//  Copyright © 2020 sunfei. All rights reserved.
//

#import "MMArgoraSourceMediaIO.h"
#import "MDRecordCamera.h"
#import "MMAgoraCamera.h"

#import "MMDeviceMotionObserver.h"
static void * kMDRecordCameraAdapterKey = &kMDRecordCameraAdapterKey;

@interface MMArgoraSourceMediaIO ()<MDRecordCameraDelegate,MMAgoraCameraDelegate,MMDeviceMotionHandling>
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong) MDRecordCamera *camera;
@property (nonatomic, strong) MMAgoraCamera *agroCamera;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;


@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, assign) AVCaptureDevicePosition position;
@property (nonatomic, strong) id<NSObject> viewOrientationObserver;

@end

@implementation MMArgoraSourceMediaIO

- (instancetype)initWithBeautyAppID:(NSString *)appid{
    self = [super init];
    if (self) {
        self.appId = appid;
        [MMDeviceMotionObserver startMotionObserve];
        [MMDeviceMotionObserver addDeviceMotionHandler:self];
        self.position = AVCaptureDevicePositionFront;
        self.sessionQueue = dispatch_queue_create("com.immomo.recordsdk.camera.adapter", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0));
        dispatch_queue_set_specific(self.sessionQueue, kMDRecordCameraAdapterKey, (__bridge void *)self, NULL);
        
        self.render = [[MMBeautyRender alloc] initWithAppId:self.appId];
        
        self.viewOrientationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillChangeStatusBarOrientationNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            UIInterfaceOrientation orientation = (UIInterfaceOrientation)note.userInfo[UIApplicationStatusBarOrientationUserInfoKey];
            self.orientation = orientation;
        }];
        
    }
    return self;
}
#pragma mark - Camera
- (void)setupCamera{
    MDRecordCameraConfiguration *config = [[MDRecordCameraConfiguration alloc] init];
    config.sessionPreset = AVCaptureSessionPreset1280x720;
    config.position = AVCaptureDevicePositionFront;
    config.disableAutoConfigAudioSession = NO;
    _camera = [[MDRecordCamera alloc]initWithConfiguration:config];
    _camera.delegate = self;
    _camera.videoCaptureDeviceFrameRate = 30;
}

- (void)startCapture {
    MDRecordCameraConfiguration *configuration = [[MDRecordCameraConfiguration alloc] init];
    configuration.sessionPreset = AVCaptureSessionPreset640x480;
    configuration.position = self.position;
    configuration.disableAutoConfigAudioSession = NO;
    [self.camera startRunningWithConfiguration:configuration];
}

- (void)stopCapture {

    [self.camera stopRunning];
}

- (void)rotateCamera {
    if (self.position == AVCaptureDevicePositionFront) {
        self.position = AVCaptureDevicePositionBack;
    } else {
        self.position = AVCaptureDevicePositionFront;
    }
    [self.camera stopRunning];
    [self.camera rotateCamera];
    [self startCapture];

}


#pragma mark - AgoraVideoSourceProtocol methods
@synthesize consumer = _consumer;

- (BOOL)shouldInitialize {

    [self setupCamera];
    return YES;
}

- (void)shouldStart {
    [self startCapture];
}

- (void)shouldStop {

    [self stopCapture];
}

- (void)shouldDispose {
    self.agroCamera = nil;
    self.camera = nil;
}

- (AgoraVideoBufferType)bufferType {
    return AgoraVideoBufferTypePixelBuffer;
}

- (AgoraVideoCaptureType)captureType {
    return AgoraVideoCaptureTypeCamera;
}

- (AgoraVideoContentHint)contentHint {
    return AgoraVideoContentHintNone;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.viewOrientationObserver];
    self.viewOrientationObserver = nil;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate methods

- (void)recordCamera:(MDRecordCamera *)camera didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMSampleTimingInfo timingInfo = kCMTimingInfoInvalid;
    CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timingInfo);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDescription);
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (mediaType == kCMMediaType_Video) {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferRetain(pixelBuffer);
        NSError *error = nil;
        [self.render setBeautyFactor:1 forKey:SKIN_SMOOTH];
        [self.render setBeautyFactor:1 forKey:TEETHWHITEN];
        CVPixelBufferRef renderBuffer = [self.render renderPixelBuffer:pixelBuffer error:&error];
        [self.consumer consumePixelBuffer:renderBuffer withTimestamp:timestamp rotation:AgoraVideoRotationNone];
        CVPixelBufferRelease(pixelBuffer);
        
    }
}

- (void)runAsyncCameraOperationOnSessionQueue:(void(^)(void))block {
    if (dispatch_get_specific(kMDRecordCameraAdapterKey)) {
        block();
    } else {
        dispatch_async(self.sessionQueue, block);
    }
}

- (void)handleDeviceMotionOrientation:(UIDeviceOrientation)orientation {
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            self.render.cameraRotate = MMRenderModuleCameraRotate90;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.render.cameraRotate = MMRenderModuleCameraRotate0;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.render.cameraRotate = MMRenderModuleCameraRotate180;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            self.render.cameraRotate = MMRenderModuleCameraRotate270;
            break;
            
        default:
            break;
    }
}

// 设置美颜参数
- (void)setBeautyFactor:(float)value forKey:(MMBeautyFilterKey)key{
    [self.render setBeautyFactor:value forKey:key];
}

- (void)setBeautyWhiteVersion:(NSInteger)version{
    [self.render setBeautyWhiteVersion:version];
}
- (void)setBeautyreddenVersion:(NSInteger)version{
    [self.render setBeautyreddenVersion:version];
}

- (void)setAutoBeautyWithType:(MMBeautyAutoType)type{
    [self.render setAutoBeautyWithType:type];
}
- (void)setMakeupLipsType:(NSUInteger)type{
    [self.render setMakeupLipsType:type];
}
// 设置lookup素材路径
- (void)setLookupPath:(NSString *)lookupPath{
    [self.render setLookupPath:lookupPath];
    
}
// 设置lookup滤镜浓度
- (void)setLookupIntensity:(CGFloat)intensity{
    [self.render setLookupIntensity:intensity];
}
// 清除滤镜效果
- (void)clearLookup{
    [self.render clearLookup];
}

// 设置贴纸资源路径
- (void)setMaskModelPath:(NSString *)path{
    [self.render setMaskModelPath:path];
}
- (void)clearSticker{
    [self.render clearSticker];
}

// 美妆效果
- (void)addMakeupPath:(NSString *)path{
    [self.render addMakeupPath:path];
}
- (void)clearMakeup{
    [self.render clearMakeup];
}
- (void)removeMakeupLayerWithType:(MMBeautyFilterKey)type{
    [self.render removeMakeupLayerWithType:type];
}
@end
