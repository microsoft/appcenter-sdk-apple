#import <OCMock/OCMock.h>

#import "MobileCenter.h"
#import "MSDistributeTestUtil.h"
#import "MSUtility+Environment.h"

static id _mobileCenterMock;
static id _utilMock;

@implementation MSDistributeTestUtil

+ (void)mockUpdatesAllowedConditions {
  self.mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  OCMStub([self.mobileCenterMock isDebuggerAttached]).andReturn(NO);
  self.utilMock = OCMClassMock([MSUtility class]);
  OCMStub([self.utilMock isRunningInDebugConfiguration]).andReturn(NO);
  OCMStub([self.utilMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
}

+ (void)unMockUpdatesAllowedConditions {
  [self.mobileCenterMock stopMocking];
  [self.utilMock stopMocking];
}

+ (id)mobileCenterMock {
  return _mobileCenterMock;
}

+ (void)setMobileCenterMock:(id)mobileCenterMock {
  _mobileCenterMock = mobileCenterMock;
}

+ (id)utilMock {
  return _utilMock;
}

+ (void)setUtilMock:(id)utilMock {
  _utilMock = utilMock;
}

@end
