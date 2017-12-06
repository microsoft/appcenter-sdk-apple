#import "MSDistributeInternal.h"
#import "MSKeychainUtil+DistributeMigration.h"
#import "MSKeychainUtilPrivate.h"
#import "MSUtility.h"

@implementation MSKeychainUtil (DistributeMigration)

+ (void)migrateDistributeData {

  // Migrate Mobile Center update token.
  NSString *mcServiceName =
      [NSString stringWithFormat:@"%@.%@", @"MobileCenter", [MS_APP_MAIN_BUNDLE bundleIdentifier]];
  NSString *mcUpdateToken = [MSKeychainUtil stringForKey:kMSUpdateTokenKey withServiceName:mcServiceName];
  NSString *acUpdateToken = [MSKeychainUtil stringForKey:kMSUpdateTokenKey];
  if (!acUpdateToken && mcUpdateToken) {
    [MSKeychainUtil storeString:mcUpdateToken forKey:kMSUpdateTokenKey];
    [MSKeychainUtil deleteStringForKey:kMSUpdateTokenKey withServiceName:mcServiceName];
  }
}

@end
