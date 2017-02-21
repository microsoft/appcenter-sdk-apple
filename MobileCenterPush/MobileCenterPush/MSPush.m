#import "MSPush.h"
#import "MSPushPrivate.h"
#import "MSPushInternal.h"
#import "MSMobileCenterInternal.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Push";

/**
 * Singleton
 */
static MSPush *sharedInstance = nil;
static dispatch_once_t onceToken;

@implementation MSPush

#pragma mark - Service initialization

- (instancetype)init {

  self = [super init];

  if (self) {

  }

  return self;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [self new];
    }
  });
  return sharedInstance;
}

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];

  MSLogVerbose([MSPush logTag], @"Started push service.");
}

+ (NSString *)logTag {
  return @"MobileCenterPush";
}

- (NSString *)storageKey {
  return kMSServiceName;
}

- (MSPriority)priority {
  return MSPriorityDefault;
}

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityDefault;
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {

    MSLogInfo([MSPush logTag], @"Push service has been enabled.");
  } else {

    MSLogInfo([MSPush logTag], @"Push service has been disabled.");
  }
}

#pragma mark - Private methods

- (BOOL)validateProperties:(NSDictionary<NSString *, NSString *> *)properties {
  for (id key in properties) {
    if (![key isKindOfClass:[NSString class]] || ![[properties objectForKey:key] isKindOfClass:[NSString class]]) {
      return NO;
    }
  }
  return YES;
}

+ (void)resetSharedInstance {

  // resets the once_token so dispatch_once will run again
  onceToken = 0;
  sharedInstance = nil;
}

#pragma mark - MSChannelDelegate

- (void)channel:(id)channel willSendLog:(id<MSLog>)log {
  if (!self.delegate) {
    return;
  }
}

- (void)channel:(id<MSChannel>)channel didSucceedSendingLog:(id<MSLog>)log {
  if (!self.delegate) {
    return;
  }
}

- (void)channel:(id<MSChannel>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  if (!self.delegate) {
    return;
  }
}

@end
