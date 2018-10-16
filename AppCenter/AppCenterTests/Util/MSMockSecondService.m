#import "MSChannelUnitConfiguration.h"
#import "MSMockSecondService.h"

static NSString *const kMSServiceName = @"MSMockSecondService";
static NSString *const kMSGroupId = @"MSSecondMock";
static MSMockSecondService *sharedInstance = nil;

@implementation MSMockSecondService

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

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)__unused logManager appSecret:(NSString *)__unused appSecret {
  self.started = YES;
}

- (void)applyEnabledState:(BOOL)__unused isEnabled {
}

- (BOOL)isAppSecretRequired {
  return NO;
}

- (BOOL)isAvailable {
  return self.started;
}

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityDefault;
}

@end
