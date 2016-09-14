/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMAbstractLog.h"
#import "SNMLogContainer.h"
#import "SonomaCore+Internal.h"
#import <XCTest/XCTest.h>

@interface SNMLogContainerTests : XCTestCase

@end

@implementation SNMLogContainerTests

- (void)testLogContainerSerialization {

  // If
  SNMLogContainer *logContainer = [[SNMLogContainer alloc] init];

  SNMAbstractLog *log1 = [[SNMAbstractLog alloc] init];
  log1.sid = kSNMUUIDString;
  log1.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

  SNMAbstractLog *log2 = [[SNMAbstractLog alloc] init];
  log2.sid = kSNMUUIDString;
  log2.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

  logContainer.logs = (NSArray<SNMLog> *)@[ log1, log2 ];

  // When
  NSString *jsonString = [logContainer serializeLog];

  // Then
  XCTAssertTrue([jsonString length] > 0);
}

@end
