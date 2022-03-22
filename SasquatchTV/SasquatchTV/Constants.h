// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

static NSString *const kMSManualSessionTracker = @"kMSManualSessionTracker";

@interface Constants : NSObject

@property(class, atomic, copy) NSString *kMSSwiftAppSecret;
@property(class, atomic, copy) NSString *kMSObjcAppSecret;

@end
