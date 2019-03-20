// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSDistributeDataMigration : NSObject

/**
 * Migrate Distribute data from previous versions in keychain.
 */
+ (void)migrateKeychain;

@end

NS_ASSUME_NONNULL_END
