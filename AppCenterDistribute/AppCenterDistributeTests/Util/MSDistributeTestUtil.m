// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDistributeTestUtil.h"
#import "AppCenter.h"
#import "MSGuidedAccessUtil.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Environment.h"

static NSString *const kMSTestReleaseHash = @"RELEASEHASH";

static id _appCenterMock;
static id _utilMock;
static id _guidedAccessUtilMock;

@implementation MSDistributeTestUtil

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
  self.appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([self.appCenterMock isDebuggerAttached]).andReturn(NO);
  self.utilMock = OCMClassMock([MSUtility class]);
  OCMStub([self.utilMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  self.guidedAccessUtilMock = OCMClassMock([MSGuidedAccessUtil class]);
  OCMStub([self.guidedAccessUtilMock isGuidedAccessEnabled]).andReturn(NO);
}

+ (void)unMockUpdatesAllowedConditions {
  [self.appCenterMock stopMocking];
  [self.utilMock stopMocking];
  [self.guidedAccessUtilMock stopMocking];
}

@end
