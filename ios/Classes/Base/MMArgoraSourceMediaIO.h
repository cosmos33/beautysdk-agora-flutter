//
//  MMArgoraSourceMediaIO.h
//  MMArgoraBeautyKitDemo
//
//  Created by sunfei on 2020/11/23.
//  Copyright © 2020 sunfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AgoraRtcKit/AgoraRtcEngineKit.h>
#import "MMBeautyRender.h"

NS_ASSUME_NONNULL_BEGIN

@class MMArgoraSourceMediaIO;


@interface MMArgoraSourceMediaIO : NSObject <AgoraVideoSourceProtocol>

@property (nonatomic, strong) MMBeautyRender *render;

- (void)rotateCamera;

- (instancetype)initWithBeautyAppID:(NSString *)appid;

// 设置美颜参数
- (void)setBeautyFactor:(float)value forKey:(MMBeautyFilterKey)key;

- (void)setBeautyWhiteVersion:(NSInteger)version;
- (void)setBeautyreddenVersion:(NSInteger)version;

- (void)setAutoBeautyWithType:(MMBeautyAutoType)type;
- (void)setMakeupLipsType:(NSUInteger)type;
// 设置lookup素材路径
- (void)setLookupPath:(NSString *)lookupPath;
// 设置lookup滤镜浓度
- (void)setLookupIntensity:(CGFloat)intensity;
// 清除滤镜效果
- (void)clearLookup;

// 设置贴纸资源路径
- (void)setMaskModelPath:(NSString *)path;
- (void)clearSticker;

// 美妆效果
- (void)addMakeupPath:(NSString *)path;
- (void)clearMakeup;
- (void)removeMakeupLayerWithType:(MMBeautyFilterKey)type;

@end

NS_ASSUME_NONNULL_END
