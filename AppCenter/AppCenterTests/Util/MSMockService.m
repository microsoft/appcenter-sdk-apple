#import "MSMockService.h"
#import "MSChannelUnitConfiguration.h"

static NSString *const kMSServiceName = @"MSMockService";
static NSString *const kMSGroupId = @"MSMock";
static MSMockService *sharedInstance = nil;

@implementation MSMockService

@synthesize appSecret;
@synthesize available;
@synthesize initializationPriority;
@synthesize channelGroup;
@synthesize channelUnit;
@synthesize channelUnitConfiguration;
@synthesize defaultTransmissionTargetToken;

- (instancetype)init {
  if ((self = [super init])) {
    // Init channel configuration.
    channelUnitConfiguration = [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];
  }
  return self;
}

+ (instancetype)sharedInstance {
  if (sharedInstance == nil) {
    sharedInstance = [[self alloc] init];
  }
  return sharedInstance;
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
  [self setStarted:YES];
}

- (void)applyEnabledState:(BOOL)__unused isEnabled {
}

@end
