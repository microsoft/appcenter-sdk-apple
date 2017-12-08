#import "MSMockSecondService.h"
#import "MSChannelConfiguration.h"

static NSString *const kMSServiceName = @"MSMockSecondService";
static NSString *const kMSGroupId = @"MSSecondMock";
static MSMockSecondService *sharedInstance = nil;

@implementation MSMockSecondService

@synthesize appSecret;
@synthesize available;
@synthesize initializationPriority;
@synthesize logManager;
@synthesize channelConfiguration;

- (instancetype)init {
  if ((self = [super init])) {
    // Init channel configuration.
    channelConfiguration = [[MSChannelConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];
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

- (NSString *)groupId {
  return kMSGroupId;
}

+ (NSString *)logTag {
  return @"AppCenterTest";
}

- (void)startWithLogManager:(id<MSLogManager>)__unused logManager appSecret:(NSString *)__unused appSecret {
  [self setStarted:YES];
}

- (void)applyEnabledState:(BOOL)__unused isEnabled {
}

@end
