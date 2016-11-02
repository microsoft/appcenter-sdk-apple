/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAbstractLog.h"
#import "MSLogContainer.h"
#import "MobileCenter+Internal.h"
#import <XCTest/XCTest.h>

@interface MSLogContainerTests : XCTestCase

@end

@implementation MSLogContainerTests

- (void)testLogContainerSerialization {

  // If
  MSLogContainer *logContainer = [[MSLogContainer alloc] init];

  MSAbstractLog *log1 = [[MSAbstractLog alloc] init];
  log1.sid = kSNMUUIDString;
  log1.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

  MSAbstractLog *log2 = [[MSAbstractLog alloc] init];
  log2.sid = kSNMUUIDString;
  log2.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

  logContainer.logs = (NSArray<MSLog> *)@[ log1, log2 ];

  // When
  NSString *jsonString = [logContainer serializeLog];

  // Then
  XCTAssertTrue([jsonString length] > 0);
}

@end
