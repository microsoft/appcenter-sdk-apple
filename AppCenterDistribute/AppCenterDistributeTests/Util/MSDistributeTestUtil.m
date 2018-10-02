#import "AppCenter.h"
#import "MSDistributeTestUtil.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Environment.h"

static id _appCenterMock;
static id _utilMock;

@implementation MSDistributeTestUtil

+ (void)mockUpdatesAllowedConditions {
  self.appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([self.appCenterMock isDebuggerAttached]).andReturn(NO);
  self.utilMock = OCMClassMock([MSUtility class]);
  OCMStub([self.utilMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
}

+ (void)unMockUpdatesAllowedConditions {
  [self.appCenterMock stopMocking];
  [self.utilMock stopMocking];
}

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

@end
