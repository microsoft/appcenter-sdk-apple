// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSCompression.h"
#import "MSConstants+Internal.h"
#import "MSDevice.h"
#import "MSDeviceInternal.h"
#import "MSHttpCall.h"
#import "MSHttpIngestionPrivate.h"
#import "MSHttpTestUtil.h"
#import "MSMockLog.h"
#import "MSTestFrameworks.h"
#import "NSURLRequest+HTTPBodyTesting.h"
#import "HTTPStubs.h"
@interface MSHttpCallTests : XCTestCase
@end

@implementation MSHttpCallTests

- (void)testCompressHTTPBodyWhenLarge {

  // If

  // HTTP body is big enough to be compressed.
  NSString *longString = [@"" stringByPaddingToLength:kMSHTTPMinGZipLength withString:@"h" startingAtIndex:0];
  NSData *longData = [longString dataUsingEncoding:NSUTF8StringEncoding];
  NSData *expectedData = [MSCompression compressData:longData];
  NSDictionary *expectedHeaders =
      @{kMSHeaderContentEncodingKey : kMSHeaderContentEncoding, kMSHeaderContentTypeKey : kMSAppCenterContentType};

  // When
  MSHttpCall *call =
      [[MSHttpCall alloc] initWithUrl:[NSURL new]
                               method:@"POST"
                              headers:nil
                                 data:longData
                       retryIntervals:@[]
                   compressionEnabled:YES
                    completionHandler:^(__unused NSData *responseBody, __unused NSHTTPURLResponse *response, __unused NSError *error){
                    }];

  // Then
  XCTAssertEqualObjects(call.data, expectedData);
  XCTAssertEqualObjects(call.headers, expectedHeaders);
}

- (void)testDoesNotCompressHTTPBodyWhenSmall {

  // If

  // HTTP body is small and will not be compressed.
  NSData *shortData = [NSData dataWithBytes:"hi" length:2];
  NSDictionary *expectedHeaders = @{kMSHeaderContentTypeKey : kMSAppCenterContentType};

  // When
  MSHttpCall *call =
      [[MSHttpCall alloc] initWithUrl:[NSURL new]
                               method:@"POST"
                              headers:nil
                                 data:shortData
                       retryIntervals:@[]
                   compressionEnabled:YES
                    completionHandler:^(__unused NSData *responseBody, __unused NSHTTPURLResponse *response, __unused NSError *error){
                    }];

  // Then
  XCTAssertEqualObjects(call.data, shortData);
  XCTAssertEqualObjects(call.headers, expectedHeaders);
}

- (void)testDoesNotCompressHTTPBodyWhenDisabled {

  // If

  // HTTP body is big enough to be compressed.
  NSString *longString = [@"" stringByPaddingToLength:kMSHTTPMinGZipLength withString:@"h" startingAtIndex:0];
  NSData *longData = [longString dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *expectedHeaders = @{kMSHeaderContentTypeKey : kMSAppCenterContentType};

  // When
  MSHttpCall *call =
      [[MSHttpCall alloc] initWithUrl:[NSURL new]
                               method:@"POST"
                              headers:nil
                                 data:longData
                       retryIntervals:@[]
                   compressionEnabled:NO
                    completionHandler:^(__unused NSData *responseBody, __unused NSHTTPURLResponse *response, __unused NSError *error){
                    }];

  // Then
  XCTAssertEqualObjects(call.data, longData);
  XCTAssertEqualObjects(call.headers, expectedHeaders);
}

@end
