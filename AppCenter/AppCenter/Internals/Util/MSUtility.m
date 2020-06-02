// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterInternal.h"
#import "MSLoggerInternal.h"
#import "MSUtility+Application.h"
#import "MSUtility+Date.h"
#import "MSUtility+Environment.h"
#import "MSUtility+File.h"
#import "MSUtility+PropertyValidation.h"
#import "MSUtility+StringFormatting.h"

// SDK versioning struct. Needs to be big enough to hold the info.
typedef struct {
  uint8_t info_version;
  const char ms_name[32];
  const char ms_version[32];
  const char ms_build[32];
} ms_info_t;

// SDK versioning.
static ms_info_t appcenter_library_info __attribute__((section("__TEXT,__ms_ios,regular,no_dead_strip"))) = {
  .info_version = 1,
  .ms_name = APP_CENTER_C_NAME,
  .ms_version = APP_CENTER_C_VERSION,
  .ms_build = APP_CENTER_C_BUILD
};

@implementation MSUtility

/**
 * @discussion Workaround for exporting symbols from category object files. See article
 * https://medium.com/ios-os-x-development/categories-in-static-libraries-78e41f8ddb96#.aedfl1kl0
 */
__attribute__((used)) static void importCategories() {
  [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@", MSUtilityApplicationCategory, MSUtilityEnvironmentCategory, MSUtilityDateCategory,
                             MSUtilityStringFormattingCategory, MSUtilityFileCategory, MSUtilityPropertyValidationCategory];
}

+ (NSString *)sdkName {
  return [NSString stringWithUTF8String:appcenter_library_info.ms_name];
}

+ (NSString *)sdkVersion {
  return [NSString stringWithUTF8String:appcenter_library_info.ms_version];
}

+ (NSObject *)unarchiveKeyedData:(NSData *)data {
  @try {
    if (@available(iOS 11.0, macOS 10.13, watchOS 4.0, *)) {
      NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:nil];
      unarchiver.requiresSecureCoding = NO;
      return [unarchiver decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:nil];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
      return [NSKeyedUnarchiver unarchiveObjectWithData:data];
#pragma clang diagnostic pop
    }
  }
  @catch(NSException *ex) {
    
    // Return nil if unarchiving fails.
    MSLogError([MSAppCenter logTag], @"Unarchiving NSData failed with error: %@", ex.reason);
    return nil;
  }
}

+ (NSData *)archiveKeyedData:(id)data {
  if (@available(macOS 10.13, iOS 11.0, watchOS 4.0, *)) {
    return [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:NO error:nil];
  } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    return [NSKeyedArchiver archivedDataWithRootObject:data];
#pragma clang diagnostic pop
  }
}

@end
