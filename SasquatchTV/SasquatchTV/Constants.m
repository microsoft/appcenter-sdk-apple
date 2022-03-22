// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "Constants.h"
#import <Foundation/Foundation.h>

@implementation Constants

+ (NSString *)kMSSwiftAppSecret {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TVOS_SWIFT_APP_SECRET"];
}

+ (NSString *)kMSObjcAppSecret {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TVOS_OBJC_APP_SECRET"];
}

@end
