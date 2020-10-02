// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACErrorDetails.h"
#import "MSACTestFrameworks.h"

@interface MSACErrorDetailsTests : XCTestCase

@end

@implementation MSACErrorDetailsTests

#pragma mark - Tests

- (void)testInitializeWithDictionary {
  NSString *filename = [[NSBundle bundleForClass:[self class]] pathForResource:@"error_details" ofType:@"json"];
  NSData *data = [NSData dataWithContentsOfFile:filename];
  MSACErrorDetails *details = [[MSACErrorDetails alloc]
      initWithDictionary:(NSMutableDictionary * _Nonnull)[NSJSONSerialization JSONObjectWithData:data
                                                                                         options:NSJSONReadingMutableContainers
                                                                                           error:NULL]];
  assertThat(details.code, equalTo(@"no_releases_for_app"));
  assertThat(details.message, equalTo(@"Couldn't get a release because there are no releases for this app."));
}

- (void)testIsValid {

  // If
  MSACErrorDetails *details = [MSACErrorDetails new];

  // Then
  XCTAssertFalse([details isValid]);

  // When
  details.code = @"some_valid_code";

  // Then
  XCTAssertFalse([details isValid]);

  // When
  details.message = @"some_error_message";

  // Then
  XCTAssertTrue([details isValid]);
}

@end
