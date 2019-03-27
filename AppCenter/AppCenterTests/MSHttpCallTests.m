// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSCompression.h"
#import "MSDevice.h"
#import "MSDeviceInternal.h"
#import "MSHttpCall.h"
#import "MSHttpIngestionPrivate.h"
#import "MSHttpTestUtil.h"
#import "MSIngestionCall.h"
#import "MSIngestionDelegate.h"
#import "MSMockLog.h"
#import "MSTestFrameworks.h"
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface MSHttpCallTests : XCTestCase
@end

@implementation MSHttpCallTests

- (void)testCompressHTTPBodyWhenLarge {

  // If

  // HTTP body is big enough to be compressed.
  NSData *longData = [NSData dataWithBytes:"h" length:kMSHTTPMinGZipLength];
  NSData *expectedData = [MSCompression compressData:longData];
  NSDictionary *expectedHeaders = @{kMSHeaderContentEncodingKey : kMSHeaderContentEncoding};

  // When
  MSHttpCall *call =
      [[MSHttpCall alloc] initWithUrl:[NSURL new]
                               method:@"POST"
                              headers:nil
                                 data:longData
                       retryIntervals:@[]
                    completionHandler:^(__unused NSData *responseBody, __unused NSHTTPURLResponse *response, __unused NSError *error){
                    }];

  // Then
  XCTAssertEqualObjects(call.data, expectedData);
  XCTAssertEqualObjects(call.headers, expectedHeaders);
}

- (void)testDoesNotCompressHTTPBodyWhenSmall {

  // If

  // HTTP body is big enough to be compressed.
  NSData *shortData = [NSData dataWithBytes:"h" length:1];
  NSDictionary *expectedHeaders = @{};

  // When
  MSHttpCall *call =
      [[MSHttpCall alloc] initWithUrl:[NSURL new]
                               method:@"POST"
                              headers:nil
                                 data:shortData
                       retryIntervals:@[]
                    completionHandler:^(__unused NSData *responseBody, __unused NSHTTPURLResponse *response, __unused NSError *error){
                    }];

  // Then
  XCTAssertEqualObjects(call.data, shortData);
  XCTAssertEqualObjects(call.headers, expectedHeaders);
}

@end
