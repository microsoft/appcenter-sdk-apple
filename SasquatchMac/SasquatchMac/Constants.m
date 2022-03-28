// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "Constants.h"
#import <Foundation/Foundation.h>

@implementation Constants

+ (NSString *_Nonnull)kMSTargetToken1 {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MAC_TARGET_TOKEN1"] ?: @"";
}

+ (NSString *_Nonnull)kMSTargetToken2 {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MAC_TARGET_TOKEN2"] ?: @"";
}

+ (NSString *_Nonnull)kMSSwiftRuntimeTargetToken {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MAC_SWIFT_RUNTIME_TARGET_TOKEN"] ?: @"";
}

+ (NSString *_Nonnull)kMSSwiftTargetToken {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MAC_SWIFT_TARGET_TOKEN"] ?: @"";
}

+ (NSString *_Nonnull)kMSSwiftAppSecret {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MAC_SWIFT_APP_SECRET"] ?: @"";
}

+ (NSString *_Nonnull)kMSObjcAppSecret {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MAC_OBJC_APP_SECRET"] ?: @"";
}

+ (NSString *_Nonnull)kMSObjCTargetToken {
#if ACTIVE_COMPILATION_CONDITION_PUPPET
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MAC_OBJC_TARGET_TOKEN_PUPPET"] ?: @"";
#else
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MAC_OBJC_TARGET_TOKEN"] ?: @"";
#endif
}

+ (NSString *_Nonnull)kMSObjCRuntimeTargetToken {
#if ACTIVE_COMPILATION_CONDITION_PUPPET
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MAC_OBJC_RUNTIME_TARGET_TOKEN_PUPPET"] ?: @"";
#else
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MAC_OBJC_RUNTIME_TARGET_TOKEN"] ?: @"";
#endif
}

@end
