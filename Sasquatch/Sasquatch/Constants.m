// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "Constants.h"
#import <Foundation/Foundation.h>

@implementation Constants

+ (NSString *_Nonnull)kMSTargetToken1 {
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"IOS_TARGET_TOKEN1"] ?: @"";
}
+ (NSString *_Nonnull)kMSTargetToken2 {
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"IOS_TARGET_TOKEN2"] ?: @"";
}
+ (NSString *_Nonnull)kMSSwiftTargetToken {
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"IOS_SWIFT_TARGET_TOKEN"] ?: @"";
}
+ (NSString *_Nonnull)kMSSwiftRuntimeTargetToken {
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"IOS_SWIFT_RUNTIME_TARGET_TOKEN"] ?: @"";
}
+ (NSString *_Nonnull)kMSObjCTargetToken {
#if ACTIVE_COMPILATION_CONDITION_PUPPET
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"IOS_OBJC_TARGET_TOKEN_PUPPET"] ?: @"";
#else
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"IOS_OBJC_TARGET_TOKEN"] ?: @"";
#endif
}
+ (NSString *_Nonnull)kMSObjCRuntimeTargetToken {
#if ACTIVE_COMPILATION_CONDITION_PUPPET
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"IOS_OBJC_RUNTIME_TARGET_TOKEN_PUPPET"] ?: @"";
#else
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"IOS_OBJC_RUNTIME_TARGET_TOKEN"] ?: @"";
#endif
}
+ (NSString *_Nonnull)kMSPuppetAppSecret {
  NSString *defaultPuppetIosAppSecret = [[[NSProcessInfo processInfo] environment] objectForKey:@"PUPPET_IOS_PROD"];
  NSString *defaultPuppetMacOsAppSecret = [[[NSProcessInfo processInfo] environment] objectForKey:@"PUPPET_MACOS_PROD"];
  return [NSString stringWithFormat:@"ios=%@;macos=%@", defaultPuppetIosAppSecret, defaultPuppetMacOsAppSecret];
}
+ (NSString *_Nonnull)kMSObjcAppSecret {
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"IOS_OBJC_APP_SECRET"];
}
+ (NSString *_Nonnull)kMSSwiftCombinedAppSecret {
  return [NSString stringWithFormat:@"ios=%@;macos=%@", self.kMSSwiftAppSecret, self.kMSSwiftCatalystAppSecret];
}
+ (NSString *_Nonnull)kMSSwiftAppSecret {
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"IOS_SWIFT_APP_SECRET"] ?: @"";
}
+ (NSString *_Nonnull)kMSSwiftCatalystAppSecret {
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"CATALYST_APP_SECRET"] ?: @"";
}

@end
