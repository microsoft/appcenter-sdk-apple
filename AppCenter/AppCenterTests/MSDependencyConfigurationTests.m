// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenter.h"
#import "MSAppCenterPrivate.h"
#import "MSChannelGroupDefault.h"
#import "MSDependencyConfiguration.h"
#import "MSHttpClient.h"
#import "MSTestFrameworks.h"

@interface MSDependencyConfigurationTests : XCTestCase

@property id channelGroupDefaultClassMock;

@end

@implementation MSDependencyConfigurationTests

- (void)setUp {
  [MSAppCenter resetSharedInstance];
  self.channelGroupDefaultClassMock = OCMClassMock([MSChannelGroupDefault class]);
  OCMStub([self.channelGroupDefaultClassMock alloc]).andReturn(self.channelGroupDefaultClassMock);
  OCMStub([self.channelGroupDefaultClassMock initWithHttpClient:OCMOCK_ANY installId:OCMOCK_ANY logUrl:OCMOCK_ANY]).andReturn(nil);
}

- (void)tearDown {
  [self.channelGroupDefaultClassMock stopMocking];
  [MSAppCenter resetSharedInstance];
  [super tearDown];
}

- (void)testNotSettingDependencyCallUsesDefaultHttpClient {

  // If
  id httpClientClassMock = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClientClassMock new]).andReturn(httpClientClassMock);

  // When
  [MSAppCenter configureWithAppSecret:@"App-Secret"];

  // Then
  // Cast to void to get rid of warning that says "Expression result unused".
  OCMVerify((void)[self.channelGroupDefaultClassMock initWithHttpClient:httpClientClassMock installId:OCMOCK_ANY logUrl:OCMOCK_ANY]);

  // Cleanup
  [httpClientClassMock stopMocking];
}

- (void)testDependencyCallUsesInjectedHttpClient {

  // If
  id httpClientClassMock = OCMClassMock([MSHttpClient class]);

  // This stub is still required due to `oneCollectorChannelDelegate` that requires `MSHttpClient` instantiation.
  // Without this stub, `[MSHttpClientTests testDeleteRecoverableErrorWithoutHeadersRetried]` test will fail for macOS because
  // channel is paused by this `MSHttpClient` instance somehow.
  OCMStub([httpClientClassMock alloc]).andReturn(httpClientClassMock);
  [MSDependencyConfiguration setHttpClient:httpClientClassMock];

  // When
  [MSAppCenter configureWithAppSecret:@"App-Secret"];

  // Then
  // Cast to void to get rid of warning that says "Expression result unused".
  OCMVerify((void)[self.channelGroupDefaultClassMock initWithHttpClient:httpClientClassMock installId:OCMOCK_ANY logUrl:OCMOCK_ANY]);

  // Cleanup
  MSDependencyConfiguration.httpClient = nil;
  [httpClientClassMock stopMocking];
}

@end
