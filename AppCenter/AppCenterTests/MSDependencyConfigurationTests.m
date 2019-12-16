// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenter.h"
#import "MSAppCenterPrivate.h"
#import "MSChannelGroupDefault.h"
#import "MSDependencyConfiguration.h"
#import "MSHttpClient.h"
#import "MSTestFrameworks.h"

@interface MSDependencyConfigurationTests : XCTestCase

@property id channelGroupDefaultMock;
@property id channelGroupDefaultClassMock;

@end

@implementation MSDependencyConfigurationTests

- (void)setUp {
  self.channelGroupDefaultMock = OCMPartialMock([MSChannelGroupDefault new]);
  self.channelGroupDefaultClassMock = OCMClassMock([MSChannelGroupDefault class]);
  OCMStub([self.channelGroupDefaultClassMock alloc]).andReturn(self.channelGroupDefaultMock);
  OCMStub([self.channelGroupDefaultMock initWithHttpClient:OCMOCK_ANY installId:OCMOCK_ANY logUrl:OCMOCK_ANY]);
}

- (void)tearDown {
  [self.channelGroupDefaultMock stopMocking];
  [self.channelGroupDefaultClassMock stopMocking];
  [MSAppCenter resetSharedInstance];
  [MSDependencyConfiguration setHttpClient:nil];
}

- (void)testNotSettingDependencyCallUsesDefaultHttpClient {

  // If
  id defaultHttpClientMock = OCMPartialMock([MSHttpClient new]);
  id httpClientClassMock = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClientClassMock alloc]).andReturn(defaultHttpClientMock);

  // When
  [MSAppCenter configureWithAppSecret:@"App-Secret"];

  // Then
  OCMVerify([self.channelGroupDefaultMock initWithHttpClient:defaultHttpClientMock installId:OCMOCK_ANY logUrl:OCMOCK_ANY]);

  // Cleanup
  [defaultHttpClientMock stopMocking];
  [httpClientClassMock stopMocking];
}

- (void)testDependencyCallUsesInjectedHttpClient {

  // If
  id defaultHttpClientMock = OCMPartialMock([MSHttpClient new]);
  id httpClientClassMock = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClientClassMock alloc]).andReturn(defaultHttpClientMock);
  [MSDependencyConfiguration setHttpClient:defaultHttpClientMock];

  // When
  [MSAppCenter configureWithAppSecret:@"App-Secret"];

  // Then
  OCMVerify([self.channelGroupDefaultMock initWithHttpClient:defaultHttpClientMock installId:OCMOCK_ANY logUrl:OCMOCK_ANY]);

  // Cleanup
  [httpClientClassMock stopMocking];
  [defaultHttpClientMock stopMocking];
}

@end
