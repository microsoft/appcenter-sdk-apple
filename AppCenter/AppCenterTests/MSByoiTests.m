// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenter.h"
#import "MSAppCenterPrivate.h"
#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextPrivate.h"
#import "MSTestFrameworks.h"

static NSString *const kMSJwtFormat = @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.%@";

@interface MSJwtHelper : NSObject

+ (NSString *)createJwtWithUserId:(NSString *)userId
                       expiration:(int)expiration;

@end

@implementation MSJwtHelper

+ (NSString *)createJwtWithUserId:(NSString *)userId expiration:(int)expiration {
  NSString *jsonClaims = [NSString stringWithFormat:@"{\"sub\":\"%@\",\"exp\":\"%i\"}", userId, expiration];
  NSData *nsdata = [jsonClaims dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, base64Encoded];
  return combinedJwt;
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
  NSString *userId = @"some_user_id";
  int expiration = [[NSDate new] dateByAddingTimeInterval:86400];
  NSString *jwt = [MSJwtHelper createJwtWithUserId:userId expiration:expiration];
  NSDate *validDate = [[NSDate alloc] initWithTimeIntervalSince1970:expiration];
  [self.authTokenContextMock setAuthToken:jwt withAccountId:userId expiresOn:validDate];
  
  // When
  [MSAppCenter setAuthTokenDelegate:(id<MSAuthTokenDelegate>)^(__unused NSString *newJwt) {}];
  
  // Then
  OCMVerify([self.authTokenContextMock addDelegate:OCMOCK_ANY]);
}

- (void)testSetAuthTokenDelegateExpiredToken {
  
  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler invoked."];
  
  // Set up JWT
  NSString *userId = @"some_user_id";
  int expiration = [[NSDate new] dateByAddingTimeInterval:86400];
  NSString *jwt = [MSJwtHelper createJwtWithUserId:userId expiration:expiration];
  
  // Stub delegate mock.
  id delegateMock = OCMProtocolMock(@protocol(MSAuthTokenDelegate));
  OCMStub([delegateMock appCenter:OCMOCK_ANY acquireAuthTokenWithCompletionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    void (^completionBlock)(NSString *token);
    [invocation getArgument:&completionBlock atIndex:3];
    NSLog(@"---------------------got here----------------");
    completionBlock(jwt);
  });
  OCMStub([self.authTokenContextMock setAuthToken:OCMOCK_ANY
                                    withAccountId:OCMOCK_ANY
                                        expiresOn:OCMOCK_ANY]).andDo(^(__unused NSInvocation *invocation) {
    [expectation fulfill];
  });
  
  // When
  [MSAppCenter setAuthTokenDelegate:delegateMock];
  
  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 OCMVerify([self.authTokenContextMock setAuthToken:jwt
                                                                     withAccountId:OCMOCK_ANY
                                                                         expiresOn:[[NSDate alloc] initWithTimeIntervalSince1970:expiration]]);
                               }];
}

- (void)testSetAuthTokenDelegateInvalidClaims {
  
  // If
  // Create an expired authTokenContext
  // Create a delegate
  
  // When
  // mock to return an invalid MSAuthTokenContextDelegateWrapper
  //[MSAppCenter setAuthTokenDelegate:<#(id<MSAuthTokenDelegate>)#>]
  
  // Then
  // verify authTokenContext set to nil
}

- (void)testSetAuthTokenDelegateWrapperRemoved {
  
  // If
  // Make "authTokenContextDelegateWrapper" exist
  
  
  // When
  [MSAppCenter setAuthTokenDelegate:nil];
  
  // Then
  // Delegate should be removed
  // Auth token should be nil
}

@end
