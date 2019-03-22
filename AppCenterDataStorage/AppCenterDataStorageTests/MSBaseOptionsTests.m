// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBaseOptions.h"
#import "MSTestFrameworks.h"

@interface MSBaseOptionsTests : XCTestCase

@end

@implementation MSBaseOptionsTests

- (void)testInitWithDeviceTtl {

  // If
  NSInteger expectedTimeToLive = 60;

  // When
  MSBaseOptions *baseOptions = [[MSBaseOptions alloc] initWithDeviceTimeToLive:expectedTimeToLive];

  // Then
  XCTAssertEqual(baseOptions.deviceTimeToLive, expectedTimeToLive);
}

- (void)testInitWithCorrectDeviceTtlByDefault {

  // If
  NSInteger expectedTimeToLive = 3600;

  // When
  MSBaseOptions *baseOptions = [[MSBaseOptions alloc] init];

  // Then
  XCTAssertEqual(baseOptions.deviceTimeToLive, expectedTimeToLive);
}

@end
