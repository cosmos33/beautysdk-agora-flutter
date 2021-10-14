//
//  MMArgoraSourceMediaIO.h
//  MMArgoraBeautyKitDemo
//
//  Created by sunfei on 2020/11/23.
//  Copyright © 2020 sunfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AgoraRtcKit/AgoraRtcEngineKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MMArgoraSourceMediaIO;


@interface MMArgoraSourceMediaIO : NSObject <AgoraVideoSourceProtocol>
- (void)rotateCamera;

- (instancetype)initWithBeautyAppID:(NSString *)appid;

@end

NS_ASSUME_NONNULL_END
