//
//  MMBeautyRender.m
//  MMBeautyKit_Example
//
//  Created by sunfei on 2019/12/19.
//  Copyright © 2019 sunfei_fish@sina.cn. All rights reserved.
//

#import "MMBeautyRender.h"


@interface MMBeautyRender () <CosmosBeautySDKDelegate>
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong) MMRenderModuleManager *render;
@property (nonatomic, strong) MMRenderFilterBeautyMakeupModule *beautyDescriptor;
@property (nonatomic, strong) MMRenderFilterLookupModule *lookupDescriptor;
@property (nonatomic, strong) MMRenderFilterStickerModule *stickerDescriptor;

@end

@implementation MMBeautyRender

- (instancetype)initWithAppId:(NSString *)appId{
    if (self = [super init]) {
        [CosmosBeautySDK initSDKWithAppId:appId delegate:self];
        MMRenderModuleManager *render = [[MMRenderModuleManager alloc] init];
        render.devicePosition = AVCaptureDevicePositionFront;
        render.inputType = MMRenderInputTypeStream;
        self.render = render;
        
        _beautyDescriptor = [[MMRenderFilterBeautyMakeupModule alloc] init];
        [render registerModule:_beautyDescriptor];
        
        _lookupDescriptor = [[MMRenderFilterLookupModule alloc] init];
        [render registerModule:_lookupDescriptor];

        _stickerDescriptor = [[MMRenderFilterStickerModule alloc] init];
        [render registerModule:_stickerDescriptor];
    }
    return self;
}

- (void)dealloc {
    
}


- (void)addBeauty {
    _beautyDescriptor = [[MMRenderFilterBeautyMakeupModule alloc] init];
    [_render registerModule:_beautyDescriptor];
}

- (void)removeBeauty {
    [_render unregisterModule:_beautyDescriptor];
    _beautyDescriptor = nil;
}

- (void)addLookup {
    _lookupDescriptor = [[MMRenderFilterLookupModule alloc] init];
    [_render registerModule:_lookupDescriptor];
}

- (void)removeLookup {
    [_render unregisterModule:_lookupDescriptor];
    _lookupDescriptor = nil;
}
- (void)setMakeupLipsType:(NSUInteger)type{
    [_beautyDescriptor setMakeupLipsType:type];
}

- (void)addSticker {
    _stickerDescriptor = [[MMRenderFilterStickerModule alloc] init];
    [_render registerModule:_stickerDescriptor];
}

- (void)removeSticker {
    [_render unregisterModule:_stickerDescriptor];
    _stickerDescriptor = nil;
}

- (CVPixelBufferRef _Nullable)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                          error:(NSError * __autoreleasing _Nullable *)error {
    return [self.render renderFrame:pixelBuffer error:error];
}


- (CVPixelBufferRef _Nullable)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                        context:(MTIContext*)context
                                          error:(NSError * __autoreleasing _Nullable *)error {
    CVPixelBufferRef renderedPixelBuffer = NULL;
    renderedPixelBuffer =  [self.render renderFrame:pixelBuffer context:context error:error];
    return renderedPixelBuffer;
}


- (MTIImage *)renderToImageWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                   context:(nonnull MTIContext *)context
                                     error:(NSError *__autoreleasing  _Nullable * _Nullable)error
{
    return [self.render renderFrameToImage:pixelBuffer context:context error:error];
}

- (void)setInputType:(MMRenderInputType)inputType {
    self.render.inputType = inputType;
}

- (MMRenderInputType)inputType {
    return self.render.inputType;
}

- (void)setCameraRotate:(MMRenderModuleCameraRotate)cameraRotate {
    self.render.cameraRotate = cameraRotate;
}

- (MMRenderModuleCameraRotate)cameraRotate {
    return self.render.cameraRotate;
}

- (void)setDevicePosition:(AVCaptureDevicePosition)devicePosition {
    self.render.devicePosition = devicePosition;
}

- (AVCaptureDevicePosition)devicePosition {
    return self.render.devicePosition;
}

- (void)setBeautyFactor:(float)value forKey:(MMBeautyFilterKey)key {
    [self.beautyDescriptor setBeautyFactor:value forKey:key];
    
}
- (void)setAutoBeautyWithType:(MMBeautyAutoType)type{
    [self.beautyDescriptor adjustAutoBeautyWithType:type];
}

- (void)setBeautyWhiteVersion:(NSInteger)version{
    [self.beautyDescriptor setBeautyWhiteVersion:(MMBeautyWhittenFilterVersion)version];
}
- (void)setBeautyreddenVersion:(NSInteger)version{
    [self.beautyDescriptor setBeautyRaddenVersion:(MMBeautyReddenFilterVersion)version];
}

- (void)setLookupPath:(NSString *)lookupPath {
    [self.lookupDescriptor setLookupResourcePath:lookupPath];
    [self.lookupDescriptor setIntensity:1.0];
}

- (void)setLookupIntensity:(CGFloat)intensity {
    [self.lookupDescriptor setIntensity:intensity];
}

- (void)clearLookup {

    [self.lookupDescriptor clear];
}

- (void)setMaskModelPath:(NSString *)path {

    [self.stickerDescriptor setMaskModelPath:path];

}

- (void)clearSticker {
    [self.stickerDescriptor clear];
}
// 美妆效果
- (void)clearMakeup {
    [self.beautyDescriptor clearMakeup];
}

- (void)addMakeupPath:(NSString *)path {
    [self.beautyDescriptor addMakeupWithResourceURL:[NSURL fileURLWithPath:path]];
}

- (void)removeMakeupLayerWithType:(MMBeautyFilterKey)type {
    [self.beautyDescriptor removeMakeupLayerWithType:type];
}

#pragma mark - CosmosBeautySDKDelegate delegate

// 发生错误时，不可直接发起 `+[CosmosBeautySDK prepareBeautyResource]` 重新请求，否则会造成循环递归
- (void)context:(CosmosBeautySDK *)context result:(BOOL)result detectorConfigFailedToLoad:(NSError * _Nullable)error {
    NSLog(@"cv load error: %@", error);
}

// 发生错误时，不可直接发起  `+[CosmosBeautySDK requestAuthorization]` 重新请求，否则会造成循环递归
- (void)context:(CosmosBeautySDK *)context
authorizationStatus:(MMBeautyKitAuthrizationStatus)status
requestFailedToAuthorization:(NSError * _Nullable)error {
    NSLog(@"authorization failed: %@", error);
}



@end

