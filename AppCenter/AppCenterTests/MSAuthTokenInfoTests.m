// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenInfo.h"
#import "MSKeychainUtil.h"
#import "MSKeychainUtilPrivate.h"
#import "MSTestFrameworks.h"

@interface MSAuthTokenInfoTests : XCTestCase

@property(nonatomic) id keychainUtilMock;
@property(nonatomic, copy) NSString *acServiceName;

@end

@implementation MSAuthTokenInfoTests

- (void)setUp {
  [super setUp];
  self.keychainUtilMock = OCMClassMock([MSKeychainUtil class]);
  self.acServiceName = [NSString stringWithFormat:@"(null).%@", kMSServiceSuffix];
}

- (void)tearDown {
  [super tearDown];
  [self.keychainUtilMock stopMocking];
}

- (void)testArraySerializationDeserialization {

  // If
  NSMutableArray<MSAuthTokenInfo *> *expectedArray = [[NSMutableArray alloc] init];
  NSString *authToken = @"authToken";
  NSDate *startTime = [NSDate new];
  NSDate *endTime = [NSDate new];
  MSAuthTokenInfo *expectedTokenInfo = [[MSAuthTokenInfo alloc] initWithAuthToken:authToken andStartTime:startTime andEndTime:endTime];
  [expectedArray addObject:expectedTokenInfo];
  NSString *key = @"keyToStoreAuthTokenArray";
  __block NSMutableDictionary *attributes;
  OCMStub([self.keychainUtilMock addSecItem:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation retainArguments];
    [invocation getArgument:&attributes atIndex:2];
  });

  // When
  [MSKeychainUtil storeArray:expectedArray forKey:key];
  NSData *storedData = attributes[(__bridge id)kSecValueData];
  NSMutableArray<MSAuthTokenInfo *> *actualArray = [NSKeyedUnarchiver unarchiveObjectWithData:storedData];

  // Then
  XCTAssertEqual([actualArray count], 1);
  MSAuthTokenInfo *actualTokenInfo = actualArray[0];
  XCTAssertTrue([expectedTokenInfo.authToken isEqualToString:actualTokenInfo.authToken]);
  XCTAssertTrue([expectedTokenInfo.startTime isEqualToDate:actualTokenInfo.startTime]);
  XCTAssertTrue([expectedTokenInfo.endTime isEqualToDate:actualTokenInfo.endTime]);
}

@end
