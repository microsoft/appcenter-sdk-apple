// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACDistributeTestUtil.h"
#import "AppCenter.h"
#import "MSACGuidedAccessUtil.h"
#import "MSACTestFrameworks.h"
#import "MSACUtility+Environment.h"

static NSString *const kMSACTestReleaseHash = @"RELEASEHASH";

static id _appCenterMock;
static id _utilMock;
static id _guidedAccessUtilMock;

@implementation MSACDistributeTestUtil

+ (id)appCenterMock {
  return _appCenterMock;
}

+ (void)setAppCenterMock:(id)appCenterMock {
  _appCenterMock = appCenterMock;
}

+ (id)utilMock {
  return _utilMock;
}

+ (void)setUtilMock:(id)utilMock {
  _utilMock = utilMock;
}

+ (id)guidedAccessUtilMock {
  return _guidedAccessUtilMock;
}

+ (void)setGuidedAccessUtilMock:(id)guidedAccessUtilMock {
  _guidedAccessUtilMock = guidedAccessUtilMock;
}

+ (void)mockUpdatesAllowedConditions {
  self.appCenterMock = OCMClassMock([MSACAppCenter class]);
  OCMStub([self.appCenterMock isDebuggerAttached]).andReturn(NO);
  self.utilMock = OCMClassMock([MSACUtility class]);
  OCMStub([self.utilMock currentAppEnvironment]).andReturn(MSACEnvironmentOther);
  self.guidedAccessUtilMock = OCMClassMock([MSACGuidedAccessUtil class]);
  OCMStub([self.guidedAccessUtilMock isGuidedAccessEnabled]).andReturn(NO);
}

+ (void)unMockUpdatesAllowedConditions {
  [self.appCenterMock stopMocking];
  [self.utilMock stopMocking];
  [self.guidedAccessUtilMock stopMocking];
}

@end
