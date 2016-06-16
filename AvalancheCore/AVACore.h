//
//  AVACore.h
//  AvalancheSDK-iOS
//
//  Created by Christoph Wendt on 6/15/16.
//
//

#import <Foundation/Foundation.h>

@interface AVACore : NSObject

+ (void)useFeatures:(NSArray<Class> *)features;
+ (void)useFeatures:(NSArray<Class> *)features identifier:(NSString *)identifier;

@end
