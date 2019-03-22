// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentUtils.h"
#import "MSTestFrameworks.h"

@interface MSDocumentUtilsTests : XCTestCase

@end

@implementation MSDocumentUtilsTests

- (void)testDocumentPayloadWithDocumentIdReturnsCorrectDictionary {

  // If
  NSString *documentId = @"documentId";
  NSString *partition = @"partition";
  NSDictionary *document = @{@"documentKey" : @"documentValue"};

  // When
  NSDictionary *actualDic = [MSDocumentUtils documentPayloadWithDocumentId:documentId partition:partition document:document];

  // Then
  XCTAssertEqualObjects(actualDic[@"document"], document);
  XCTAssertEqualObjects(actualDic[@"PartitionKey"], partition);
  XCTAssertEqualObjects(actualDic[@"id"], documentId);
}

@end
