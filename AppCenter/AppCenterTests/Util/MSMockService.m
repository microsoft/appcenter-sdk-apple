#import "MSMockService.h"
#import "MSChannelConfiguration.h"

static NSString *const kMSServiceName = @"MSMockService";
static NSString *const kMSGroupId = @"MSMock";
static MSMockService *sharedInstance = nil;

@implementation MSMockService

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

- (void)applyEnabledState:(BOOL)__unused isEnabled {
}

@end
