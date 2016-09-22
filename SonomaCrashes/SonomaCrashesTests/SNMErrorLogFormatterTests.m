/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "SNMErrorLogFormatterPrivate.h"

@interface SNMErrorLogFormatterTests : XCTestCase

@end

@implementation SNMErrorLogFormatterTests

- (void)testAnonymizedPathWorks {
  NSString *testPath = @"/var/containers/Bundle/Application/2A0B0E6F-0BF2-419D-A699-FCDF8ADECD8C/Puppet.app/Puppet";
  NSString *expected = testPath;
  NSString *actual = [SNMErrorLogFormatter anonymizedPathFromPath:testPath];
  assertThat(actual, equalTo(expected));
  
  testPath = @"/Users/someone/Library/Developer/CoreSimulator/Devices/B8321AD0-C30B-41BD-BA54-5A7759CEC4CD/data/Containers/Bundle/Application/8CC7B5B5-7841-45C4-BAC2-6AA1B944A5E1/Puppet.app/Puppet";
  expected = @"/Users/USER/Library/Developer/CoreSimulator/Devices/B8321AD0-C30B-41BD-BA54-5A7759CEC4CD/data/Containers/Bundle/Application/8CC7B5B5-7841-45C4-BAC2-6AA1B944A5E1/Puppet.app/Puppet";
  actual = [SNMErrorLogFormatter anonymizedPathFromPath:testPath];
  assertThat(actual, equalTo(expected));
  XCTAssertFalse([actual containsString:@"sampleuser"]);
  XCTAssertTrue([actual hasPrefix:@"/Users/USER/"]);
}

@end
