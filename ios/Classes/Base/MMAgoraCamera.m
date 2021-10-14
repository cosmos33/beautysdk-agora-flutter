//
//  MMCamera.m
//  MMArgoraBeautyKitDemo
//
//  Created by sunfei on 2020/11/24.
//  Copyright © 2020 sunfei. All rights reserved.
//

#import "MMAgoraCamera.h"

@interface MMAgoraCamera () <AVCaptureVideoDataOutputSampleBufferDelegate>


@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_queue_t captureQueue;
@property (nonatomic, readonly) AVCaptureVideoDataOutput *currentOutput;

@end

@implementation MMAgoraCamera

- (instancetype)init
{
    self = [super init];
    if (self) {
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.usesApplicationAudioSession = NO;
        
        [_captureSession beginConfiguration];
        AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
        captureOutput.alwaysDiscardsLateVideoFrames = YES;
        captureOutput.videoSettings = @{ (__bridge id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) };
        if ([_captureSession canAddOutput:captureOutput]) {
            [_captureSession addOutput:captureOutput];
        }
        [_captureSession commitConfiguration];
        
        _position = AVCaptureDevicePositionFront;
        
        _captureQueue = dispatch_queue_create("com.cosmos.camera", NULL);
    }
    return self;
}

- (AVCaptureVideoDataOutput *)currentOutput {
    return self.captureSession.outputs.firstObject;
}

- (void)switchCamera {
    if (self.position == AVCaptureDevicePositionFront) {
        self.position = AVCaptureDevicePositionBack;
        
    } else {
        self.position = AVCaptureDevicePositionFront;
    }
    
    dispatch_async(self.captureQueue, ^{
        if (!self.captureSession.isRunning) {
            return;
        }
        [self stopCapture];
        [self startCapture];
    });
}

- (void)startCapture {
    if (!self.currentOutput) {
        return;
    }
    
    [self.currentOutput setSampleBufferDelegate:self queue:self.captureQueue];
    dispatch_async(self.captureQueue, ^{
        [self changeCaptureDeviceToPosition:self.position ofSession:self.captureSession];
        [self.captureSession beginConfiguration];
        if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        }
        [self.captureSession commitConfiguration];
        
        [self.currentOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation = AVCaptureVideoOrientationPortrait;
        [self.currentOutput connectionWithMediaType:AVMediaTypeVideo].videoMirrored = (self.position == AVCaptureDevicePositionFront);
        
        [self.captureSession startRunning];
    });
}

- (void)stopCapture {
    [self.currentOutput setSampleBufferDelegate:nil queue:nil];
    dispatch_async(self.captureQueue, ^{
        [self.captureSession stopRunning];
    });
}

- (void)changeCaptureDeviceToPosition:(AVCaptureDevicePosition)position ofSession:(AVCaptureSession *)session {
    AVCaptureDevice *captureDevice = [self captureDeviceWithPosition:position];
    if (!captureDevice) {
        return;
    }
    
    AVCaptureDeviceInput *currentInput = self.captureSession.inputs.firstObject;
    if (currentInput && currentInput.device.localizedName != captureDevice.uniqueID) {
        return;
    }
    
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    if (!newInput) {
        return;
    }
    
    [session beginConfiguration];
    [session removeInput:currentInput];
    [session addInput:newInput];
    [session commitConfiguration];
}

- (AVCaptureDevice *)captureDeviceWithPosition:(AVCaptureDevicePosition)position {
    return [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position].devices.firstObject;
}

- (void)dealloc
{
    self.captureQueue = nil;
    self.captureSession = nil;
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer fromConnection:(nonnull AVCaptureConnection *)connection{
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    if(!pixelBuffer) {
        return;
    }
    CVPixelBufferRetain(pixelBuffer);
    [self.delegate camera:self didOutputPixelBuffer:pixelBuffer timestamp:timestamp];
    CVPixelBufferRelease(pixelBuffer);
}

@end
