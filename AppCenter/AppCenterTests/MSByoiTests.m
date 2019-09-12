// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenter.h"
#import "MSAppCenterPrivate.h"
#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextDelegateWrapper.h"
#import "MSAuthTokenContextPrivate.h"
#import "MSAuthTokenValidityInfo.h"
#import "MSTestFrameworks.h"

static NSString *const kMSJwtFormat = @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.%@";

@interface MSJwtHelper : NSObject

+ (NSString *)createJwtWithUserId:(NSString *)userId expiration:(int)expiration;

@end

@implementation MSJwtHelper

+ (NSString *)createJwtWithUserId:(NSString *)userId expiration:(int)expiration {
  NSString *jsonClaims = [NSString stringWithFormat:@"{\"sub\":\"%@\",\"exp\":\"%i\"}", userId, expiration];
  NSData *nsdata = [jsonClaims dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, base64Encoded];
  return combinedJwt;
}

+ (NSString *)createJwtWithMissingExpClaim {
  NSString *userId = @"some_user_id";
  NSString *jsonClaims = [NSString stringWithFormat:@"{\"sub\":\"%@\"}", userId];
  NSData *nsdata = [jsonClaims dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  return [NSString stringWithFormat:kMSJwtFormat, base64Encoded];
}

@end

@interface MSByoiTests : XCTestCase

@property(nonatomic) MSAppCenter *sut;
@property(nonatomic) id authTokenContextMock;

@end

@implementation MSByoiTests

- (void)setUp {
  [super setUp];

  // Auth token context.
  [MSAuthTokenContext resetSharedInstance];
  self.authTokenContextMock = OCMPartialMock([MSAuthTokenContext new]);
  OCMStub([self.authTokenContextMock sharedInstance]).andReturn(self.authTokenContextMock);

  // System Under Test.
  [MSAppCenter resetSharedInstance];
  self.sut = [[MSAppCenter alloc] init];
}

- (void)tearDown {
  [self.authTokenContextMock stopMocking];
  [MSAuthTokenContext resetSharedInstance];
  [super tearDown];
}

- (void)testSetAuthTokenDelegateValidToken {

  // If
  // Valid Token
  NSString *userId = @"original_user_id";
  NSString *currentJwt = [MSJwtHelper createJwtWithUserId:userId expiration:86400];
  MSAuthTokenValidityInfo *validityInfo =
      [[MSAuthTokenValidityInfo alloc] initWithAuthToken:currentJwt
                                               startTime:nil
                                                 endTime:[[NSDate alloc] initWithTimeIntervalSinceNow:86400]];
  [MSAppCenter setAuthToken:currentJwt];

  // Stub delegate mock.
  id delegateMock = OCMProtocolMock(@protocol(MSAuthTokenDelegate));
  __block int numCalls = 0;
  OCMStub([delegateMock appCenter:OCMOCK_ANY acquireAuthTokenWithCompletionHandler:OCMOCK_ANY]).andDo(^(__unused NSInvocation *invocation) {
    numCalls++;
  });

  // When
  [MSAppCenter setAuthTokenDelegate:delegateMock];
  [self.authTokenContextMock checkIfTokenNeedsToBeRefreshed:validityInfo];

  // Then
  XCTAssertEqual(0, numCalls);
}

- (void)testSetAuthTokenDelegateExpiredToken {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler invoked."];

  // Expired Token
  NSString *userId = @"original_user_id";
  NSString *currentJwt = [MSJwtHelper createJwtWithUserId:userId expiration:0];
  MSAuthTokenValidityInfo *validityInfo =
      [[MSAuthTokenValidityInfo alloc] initWithAuthToken:currentJwt startTime:nil endTime:[[NSDate alloc] initWithTimeIntervalSince1970:0]];
  [MSAppCenter setAuthToken:currentJwt];

  // Set up JWT
  userId = @"newer_user_id";
  int expiration = [[NSDate new] dateByAddingTimeInterval:86400];
  NSString *newJwt = [MSJwtHelper createJwtWithUserId:userId expiration:expiration];

  // Stub delegate mock.
  id delegateMock = OCMProtocolMock(@protocol(MSAuthTokenDelegate));
  OCMStub([delegateMock appCenter:OCMOCK_ANY acquireAuthTokenWithCompletionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    void (^completionBlock)(NSString *token);
    [invocation getArgument:&completionBlock atIndex:3];
    completionBlock(newJwt);
  });
  OCMStub([self.authTokenContextMock setAuthToken:OCMOCK_ANY withAccountId:OCMOCK_ANY expiresOn:OCMOCK_ANY])
      .andDo(^(__unused NSInvocation *invocation) {
        [expectation fulfill];
      });

  // When
  [MSAppCenter setAuthTokenDelegate:delegateMock];
  [self.authTokenContextMock checkIfTokenNeedsToBeRefreshed:validityInfo];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 OCMVerify([self.authTokenContextMock
                                      setAuthToken:newJwt
                                     withAccountId:OCMOCK_ANY
                                         expiresOn:[[NSDate alloc] initWithTimeIntervalSince1970:expiration]]);
                               }];
}

- (void)testSetAuthTokenDelegateInvalidClaims {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler invoked."];

  // Expired Token
  NSString *userId = @"original_user_id";
  NSString *currentJwt = [MSJwtHelper createJwtWithUserId:userId expiration:0];
  MSAuthTokenValidityInfo *validityInfo =
      [[MSAuthTokenValidityInfo alloc] initWithAuthToken:currentJwt startTime:nil endTime:[[NSDate alloc] initWithTimeIntervalSince1970:0]];
  [MSAppCenter setAuthToken:currentJwt];

  NSString *newJwt = [MSJwtHelper createJwtWithMissingExpClaim];

  // Stub delegate mock.
  id delegateMock = OCMProtocolMock(@protocol(MSAuthTokenDelegate));
  OCMStub([delegateMock appCenter:OCMOCK_ANY acquireAuthTokenWithCompletionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    void (^completionBlock)(NSString *token);
    [invocation getArgument:&completionBlock atIndex:3];
    completionBlock(newJwt);
  });
  OCMStub([self.authTokenContextMock setAuthToken:OCMOCK_ANY withAccountId:OCMOCK_ANY expiresOn:OCMOCK_ANY])
      .andDo(^(__unused NSInvocation *invocation) {
        [expectation fulfill];
      });

  // When
  [MSAppCenter setAuthTokenDelegate:delegateMock];
  [self.authTokenContextMock checkIfTokenNeedsToBeRefreshed:validityInfo];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 OCMVerify([self.authTokenContextMock setAuthToken:nil withAccountId:nil expiresOn:nil]);
                               }];
}

- (void)testSetAuthTokenDelegateWrapperRemoved {

  // If
  id delegateMock = OCMProtocolMock(@protocol(MSAuthTokenDelegate));
  OCMStub([delegateMock appCenter:OCMOCK_ANY acquireAuthTokenWithCompletionHandler:OCMOCK_ANY]);

  // Make "authTokenContextDelegateWrapper" exist
  [MSAppCenter setAuthTokenDelegate:delegateMock];

  // Then
  XCTAssertEqual(1, [[self.authTokenContextMock delegates] count]);

  // When
  [MSAppCenter setAuthTokenDelegate:nil];

  // Then
  XCTAssertEqual(0, [[self.authTokenContextMock delegates] count]);
  OCMVerify([self.authTokenContextMock setAuthToken:nil withAccountId:nil expiresOn:nil]);
}

- (void)testSetAuthTokenWithNilToken {

  // When
  [MSAppCenter setAuthToken:nil];

  // Then
  OCMVerify([self.authTokenContextMock setAuthToken:nil withAccountId:nil expiresOn:nil]);
}

- (void)testSetAuthTokenWithNilClaims {

  // If
  NSString *jwt = [MSJwtHelper createJwtWithMissingExpClaim];

  // When
  [MSAppCenter setAuthToken:jwt];

  // Then
  OCMVerify([self.authTokenContextMock setAuthToken:nil withAccountId:nil expiresOn:nil]);
}

@end
