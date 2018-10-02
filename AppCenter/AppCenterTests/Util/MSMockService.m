#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSMockService.h"

static NSString *const kMSServiceName = @"MSMockService";
static NSString *const kMSGroupId = @"MSMock";
static MSMockService *sharedInstance = nil;

@implementation MSMockService

@synthesize channelGroup = _channelGroup;
@synthesize channelUnit = _channelUnit;
@synthesize channelUnitConfiguration = _channelUnitConfiguration;
@synthesize appSecret = _appSecret;
@synthesize defaultTransmissionTargetToken = _defaultTransmissionTargetToken;

- (instancetype)init {
  if ((self = [super init])) {

    // Init channel configuration.
    _channelUnitConfiguration = [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];
  }
  return self;
}

+ (instancetype)sharedInstance {
  if (sharedInstance == nil) {
    sharedInstance = [[self alloc] init];
  }
  return sharedInstance;
}

+ (void)resetSharedInstance {
  sharedInstance = nil;
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

+ (NSString *)logTag {
  return @"AppCenterTest";
}

- (NSString *)groupId {
  return kMSGroupId;
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  self.startedFromApplication = fromApplication;
  self.channelGroup = channelGroup;
  self.appSecret = appSecret;
  self.defaultTransmissionTargetToken = token;
  self.started = YES;
  self.channelUnit = [self.channelGroup addChannelUnitWithConfiguration:self.channelUnitConfiguration];
}

- (void)applyEnabledState:(BOOL)__unused isEnabled {
}

- (BOOL)isAvailable {
  return self.started;
}

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityDefault;
}

@end
