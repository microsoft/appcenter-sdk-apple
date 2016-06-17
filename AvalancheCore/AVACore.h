//
//  AVACore.h
//  AvalancheSDK-iOS
//
//  Created by Christoph Wendt on 6/15/16.
//
//

#import <Foundation/Foundation.h>
#import "AVAConstants.h"

@interface AVACore : NSObject

+ (void)useFeatures:(NSArray<Class> *)features;
+ (void)useFeatures:(NSArray<Class> *)features identifier:(NSString *)identifier;

+ (AVALogLevel)logLevel;
+ (void)setLogLevel:(AVALogLevel)logLevel;
+ (void)setLogHandler:(AVALogHandler)logHandler;

@end
