/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import "AVALogContainer.h"
#import "AVAEndSessionLog.h"
#import "AVADeviceLog.h"

@interface AVALogContainerTests : XCTestCase

@end

@implementation AVALogContainerTests

- (void)testLogContainerSerialization {
  
  // If
  AVALogContainer* logContainer = [[AVALogContainer alloc] init];
  
  AVAEndSessionLog* log1 = [[AVAEndSessionLog alloc] init];
  log1.sid = [[NSUUID UUID] UUIDString];
  log1.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
  
  AVAEndSessionLog* log2 = [[AVAEndSessionLog alloc] init];
  log2.sid = [[NSUUID UUID] UUIDString];
  log2.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

  logContainer.logs = (NSArray<AVALog>*)@[log1, log2];
  
  // When
  NSString* jsonString = [logContainer serializeLog];
  
  // Then
  XCTAssertTrue([jsonString length] > 0);
}

@end
