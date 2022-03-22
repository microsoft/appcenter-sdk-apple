// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "Constants.h"
#import <Foundation/Foundation.h>

@implementation Constants

+ (NSString *_Nonnull)kMSTargetToken1 {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"IOS_TARGET_TOKEN1"] ?: @"";
}
+ (NSString *_Nonnull)kMSTargetToken2 {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"IOS_TARGET_TOKEN2"] ?: @"";
}
+ (NSString *_Nonnull)kMSSwiftTargetToken {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"IOS_SWIFT_TARGET_TOKEN"] ?: @"";
}
+ (NSString *_Nonnull)kMSSwiftRuntimeTargetToken {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"IOS_SWIFT_RUNTIME_TARGET_TOKEN"] ?: @"";
}
+ (NSString *_Nonnull)kMSObjCTargetToken {
#if ACTIVE_COMPILATION_CONDITION_PUPPET
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"IOS_OBJC_TARGET_TOKEN_PUPPET"] ?: @"";
#else
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"IOS_OBJC_TARGET_TOKEN"] ?: @"";
#endif
}
+ (NSString *_Nonnull)kMSObjCRuntimeTargetToken {
#if ACTIVE_COMPILATION_CONDITION_PUPPET
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"IOS_OBJC_RUNTIME_TARGET_TOKEN_PUPPET"] ?: @"";
#else
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"IOS_OBJC_RUNTIME_TARGET_TOKEN"] ?: @"";
#endif
}
+ (NSString *_Nonnull)kMSPuppetAppSecret {
  NSString *defaultPuppetIosAppSecret = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"PUPPET_IOS_PROD"];
  NSString *defaultPuppetMacOsAppSecret = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"PUPPET_MACOS_PROD"];
  return [NSString stringWithFormat:@"ios=%@;macos=%@", defaultPuppetIosAppSecret, defaultPuppetMacOsAppSecret];
}
+ (NSString *_Nonnull)kMSObjcAppSecret {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"IOS_OBJC_APP_SECRET"];
}
+ (NSString *_Nonnull)kMSSwiftCombinedAppSecret {
  return [NSString stringWithFormat:@"ios=%@;macos=%@", self.kMSSwiftAppSecret, self.kMSSwiftCatalystAppSecret];
}
+ (NSString *_Nonnull)kMSSwiftAppSecret {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"IOS_SWIFT_APP_SECRET"] ?: @"";
}
+ (NSString *_Nonnull)kMSSwiftCatalystAppSecret {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CATALYST_APP_SECRET"] ?: @"";
}

@end
