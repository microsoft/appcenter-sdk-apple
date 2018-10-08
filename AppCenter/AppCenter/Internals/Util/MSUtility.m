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
    .info_version = 1, .ms_name = APP_CENTER_C_NAME, .ms_version = APP_CENTER_C_VERSION, .ms_build = APP_CENTER_C_BUILD};

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

@end
