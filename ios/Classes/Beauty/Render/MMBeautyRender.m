//
//  MMBeautyRender.m
//  MMBeautyKit_Example
//
//  Created by sunfei on 2019/12/19.
//  Copyright © 2019 sunfei_fish@sina.cn. All rights reserved.
//

#import "MMBeautyRender.h"

#define LOOKUP 1
#define STICKER 1

@interface MMBeautyRender () <CosmosBeautySDKDelegate>
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong) MMRenderModuleManager *render;
@property (nonatomic, strong) MMRenderFilterBeautyMakeupModule *beautyDescriptor;

#if LOOKUP == 1
@property (nonatomic, strong) MMRenderFilterLookupModule *lookupDescriptor;
#endif

#if STICKER == 1
@property (nonatomic, strong) MMRenderFilterStickerModule *stickerDescriptor;
#endif

@end

@implementation MMBeautyRender

- (instancetype)initWithAppId:(NSString *)appId{
    if (self = [super init]) {
//        [CosmosBeautySDK initSDKWithAppId:@"your app id" delegate:self];
        NSDictionary *dic = [[NSBundle mainBundle]infoDictionary];
        [dic setValue:@"com.wemomo.momotest" forKey:@"CFBundleIdentifier"];
        [CosmosBeautySDK initSDKWithAppId:appId delegate:self];
        MMRenderModuleManager *render = [[MMRenderModuleManager alloc] init];
        render.devicePosition = AVCaptureDevicePositionFront;
        render.inputType = MMRenderInputTypeStream;
        self.render = render;
        
        _beautyDescriptor = [[MMRenderFilterBeautyMakeupModule alloc] init];
        [render registerModule:_beautyDescriptor];
        
#if LOOKUP == 1
        _lookupDescriptor = [[MMRenderFilterLookupModule alloc] init];
        [render registerModule:_lookupDescriptor];
#endif
        
#if STICKER == 1
        _stickerDescriptor = [[MMRenderFilterStickerModule alloc] init];
        [render registerModule:_stickerDescriptor];
#endif
        NSLog(@"level = %@", [CosmosBeautySDK performSelector:NSSelectorFromString(@"__authKeys__")]);
    }
           
        return self;
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
#if LOOKUP == 1
    _lookupDescriptor = [[MMRenderFilterLookupModule alloc] init];
    [_render registerModule:_lookupDescriptor];
#endif
}

- (void)removeLookup {
#if LOOKUP == 1
    [_render unregisterModule:_lookupDescriptor];
    _lookupDescriptor = nil;
#endif
}
- (void)setMakeupLipsType:(NSUInteger)type{
//    [_beautyDescriptor setMakeupLipsType:type];
}

- (void)addSticker {
#if STICKER == 1
    _stickerDescriptor = [[MMRenderFilterStickerModule alloc] init];
    [_render registerModule:_stickerDescriptor];
#endif
}

- (void)removeSticker {
#if STICKER == 1
    [_render unregisterModule:_stickerDescriptor];
    _stickerDescriptor = nil;
#endif
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
#if LOOKUP == 1
    [self.lookupDescriptor setLookupResourcePath:lookupPath];
    [self.lookupDescriptor setIntensity:1.0];
#endif
}

- (void)setLookupIntensity:(CGFloat)intensity {
#if LOOKUP == 1
    [self.lookupDescriptor setIntensity:intensity];
#endif
}

- (void)clearLookup {
#if LOOKUP == 1
    [self.lookupDescriptor clear];
#endif
}

- (void)setMaskModelPath:(NSString *)path {
#if STICKER == 1
    [self.stickerDescriptor setMaskModelPath:path];
#endif
}

- (void)clearSticker {
#if STICKER == 1
    [self.stickerDescriptor clear];
#endif
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

