// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (MSTestFixture)

/**
 * Return a JSON fixture in a Fixtures folder (relative to the current class).
 *
 * @param fixture The name of the fixture to retrieve.
 * @return The fixture's data.
 */
- (NSData *)jsonFixture:(NSString *)fixture;

@end

NS_ASSUME_NONNULL_END
