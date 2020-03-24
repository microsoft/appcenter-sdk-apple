// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSMockUserDefaults : NSUserDefaults

/**
 * Clear dictionary
 */
- (void)stopMocking;
- (void)migrateKeys:( NSDictionary *)migratedKeys forService:( NSString *)serviceName;
@end
