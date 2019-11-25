// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDistributeDataMigration.h"
#import "MSDistributeInternal.h"
#import "MSKeychainUtilPrivate.h"
#import "MSUtility.h"

@implementation MSDistributeDataMigration

+ (void)migrateKeychain {

  // Migrate Mobile Center update token.
  NSString *mcServiceName = [NSString stringWithFormat:@"%@.%@", [MS_APP_MAIN_BUNDLE bundleIdentifier], @"MobileCenter"];
  NSString *mcUpdateToken = [MSKeychainUtil stringForKey:kMSUpdateTokenKey withServiceName:mcServiceName statusCode:nil];
  NSString *acUpdateToken = [MSKeychainUtil stringForKey:kMSUpdateTokenKey statusCode:nil];
  if (!acUpdateToken && mcUpdateToken) {
    [MSKeychainUtil storeString:mcUpdateToken forKey:kMSUpdateTokenKey];
  }

  // Delete Mobile Center token.
  if (mcUpdateToken) {
    [MSKeychainUtil deleteStringForKey:kMSUpdateTokenKey withServiceName:mcServiceName];
  }
}

@end
