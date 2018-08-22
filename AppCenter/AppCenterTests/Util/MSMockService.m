#import "MSMockService.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitConfiguration.h"

static NSString *const kMSServiceName = @"MSMockService";
static NSString *const kMSGroupId = @"MSMock";
static MSMockService *sharedInstance = nil;

@implementation MSMockService

@synthesize appSecret;
@synthesize initializationPriority;
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

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  [channelGroup addDelegate:self];
  self.channelUnit = [channelGroup
      addChannelUnitWithConfiguration:
          [[MSChannelUnitConfiguration alloc]
              initDefaultConfigurationWithGroupId:[self groupId]]];
  self.appSecret = appSecret;
  self.defaultTransmissionTargetToken = token;
  self.startedFromApplication = fromApplication;
  [self setStarted:YES];
}

- (void)applyEnabledState:(BOOL)__unused isEnabled {
}

@end
