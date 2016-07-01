/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface AVAFeature : NSObject

+ (void)resume;
+ (void)stop;
+ (void)setServerURL:(NSString *)serverURL;
+ (void)setIdentifier:(NSString *)identifier;

@end
