#import "MSMockSecondService.h"
#import "MSChannelUnitConfiguration.h"

static NSString *const kMSServiceName = @"MSMockSecondService";
static NSString *const kMSGroupId = @"MSSecondMock";
static MSMockSecondService *sharedInstance = nil;

@implementation MSMockSecondService

@synthesize appSecret;
@synthesize initializationPriority;
@synthesize channelGroup;
@synthesize channelUnit;
@synthesize channelUnitConfiguration;
@synthesize defaultTransmissionTargetToken;

- (instancetype)init {
  if ((self = [super init])) {

    // Init channel configuration.
    channelUnitConfiguration = [[MSChannelUnitConfiguration alloc]
        initDefaultConfigurationWithGroupId:[self groupId]];
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

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)__unused logManager
                    appSecret:(NSString *)__unused appSecret {
  [self setStarted:YES];
}

- (void)applyEnabledState:(BOOL)__unused isEnabled {
}

- (BOOL)isAppSecretRequired {
  return NO;
}

@end
