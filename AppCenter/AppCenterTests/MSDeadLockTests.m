#import "MSAbstractLog.h"
#import "MSAppCenter.h"
#import "MSAppCenterPrivate.h"
#import "MSChannelDelegate.h"
#import "MSChannelUnitProtocol.h"
#import "MSMockService.h"
#import "MSTestFrameworks.h"

@interface MSDeadLockTests : XCTestCase
@end

@interface MSDummyService1 : MSMockService <MSChannelDelegate>
@end

@interface MSDummyService2 : MSMockService
@end

static MSDummyService1 *sharedInstanceService1 = nil;
static MSDummyService2 *sharedInstanceService2 = nil;

@implementation MSDummyService1

+ (instancetype)sharedInstance {
  if (sharedInstanceService1 == nil) {
    sharedInstanceService1 = [[self alloc] init];
  }
  return sharedInstanceService1;
}

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityMax;
}

- (NSString *)serviceName {
  return @"service1";
}

- (NSString *)groupId {
  return @"service1";
}

- (void)channel:(id<MSChannelProtocol>)channel didPrepareLog:(id<MSLog>)log internalId:(NSString *)internalId flags:(MSFlags)flags {

  // Operation locking AC while in ChannelDelegate.
  NSUUID *__unused deviceId = [MSAppCenter installId];
}
- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
  id mockLog = OCMPartialMock([MSAbstractLog new]);
  OCMStub([mockLog isValid]).andReturn(YES);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // Log enqueued from background thread (i.e. crash logs).
    [self.channelUnit enqueueItem:mockLog flags:MSFlagsDefault];
  });
}

@end

@implementation MSDummyService2

+ (instancetype)sharedInstance {
  if (sharedInstanceService2 == nil) {
    sharedInstanceService2 = [[self alloc] init];
  }
  return sharedInstanceService2;
}

- (NSString *)serviceName {
  return @"service2";
}

- (NSString *)groupId {
  return @"service2";
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  [NSThread sleepForTimeInterval:.1];
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
}

@end

@implementation MSDeadLockTests

- (void)testDeadLockAtStartup {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Not blocked."];

  // When
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // Start the SDK with interlocking sensible services.
    [MSAppCenter start:@"AppSecret" withServices:@ [[MSDummyService1 class], [MSDummyService2 class]]];
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

@end
