#import "MSDistributeDataMigration.h"
#import "MSDistributeInternal.h"
#import "MSKeychainUtilPrivate.h"
#import "MSUtility.h"

@implementation MSDistributeDataMigration

+ (void)migrateKeychain {

  // Migrate Mobile Center update token.
  NSString *mcServiceName = [NSString stringWithFormat:@"%@.%@", [MS_APP_MAIN_BUNDLE bundleIdentifier], @"MobileCenter"];
  NSString *mcUpdateToken = [MSKeychainUtil stringForKey:kMSUpdateTokenKey withServiceName:mcServiceName];
  NSString *acUpdateToken = [MSKeychainUtil stringForKey:kMSUpdateTokenKey];
  if (!acUpdateToken && mcUpdateToken) {
    [MSKeychainUtil storeString:mcUpdateToken forKey:kMSUpdateTokenKey];
  }

  // Delete Mobile Center token.
  if (mcUpdateToken) {
    [MSKeychainUtil deleteStringForKey:kMSUpdateTokenKey withServiceName:mcServiceName];
  }
}

@end
