// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "Constants.h"
#import <Foundation/Foundation.h>

@implementation Constants

+ (NSString *)kMSSwiftAppSecret {
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"TVOS_SWIFT_APP_SECRET"];
}

+ (NSString *)kMSObjcAppSecret {
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"TVOS_OBJC_APP_SECRET"];
}

@end
