#import "MSTestFrameworks.h"
#import "MSUserNotificationCenterDelegateForwarder.h"
#import "MSDelegateForwarderPrivate.h"

@interface MSUserNotificationCenterDelegateForwarderTest : XCTestCase

@property(nonatomic) MSUserNotificationCenterDelegateForwarder *sut;

@end

@implementation MSUserNotificationCenterDelegateForwarderTest

- (void)setUp {
  [super setUp];
  
  // The delegate forwarder is already set via the load method, reset it for testing.
  [MSUserNotificationCenterDelegateForwarder resetSharedInstance];
  self.sut = [MSUserNotificationCenterDelegateForwarder sharedInstance];
}

- (void)tearDown {
  [super tearDown];
  [MSUserNotificationCenterDelegateForwarder resetSharedInstance];
}

-(void)testSetEnabledYesFromPlist {
  
  // If
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock objectForInfoDictionaryKey:kMSUserNotificationCenterDelegateForwarderEnabledKey]).andReturn(@YES);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  
  // When
  [[self.sut class] load];
  
  // Then
  assertThatBool(self.sut.enabled, isTrue());
}

-(void)testSetEnabledNoFromPlist {
  
  // If
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock objectForInfoDictionaryKey:kMSUserNotificationCenterDelegateForwarderEnabledKey]).andReturn(@NO);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  
  // When
  [[self.sut class] load];
  
  // Then
  assertThatBool(self.sut.enabled, isFalse());
}

-(void)testSetEnabledNoneFromPlist {
  
  // If
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock objectForInfoDictionaryKey:kMSUserNotificationCenterDelegateForwarderEnabledKey]).andReturn(nil);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  
  // When
  [[self.sut class] load];
  
  // Then
  assertThatBool(self.sut.enabled, isTrue());
}

@end
