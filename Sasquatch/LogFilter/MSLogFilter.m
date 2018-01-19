#import "MSLogFilter.h"
#import "MSLogManager.h"
#import "MSServiceAbstractProtected.h"
#import "MSServiceAbstractInternal.h"

#import "MSServiceCommon.h"
#import "MSServiceInternal.h"
#import "MSLogManagerDelegate.h"
#import "MSLogger.h"

@interface MSLogFilter () <MSServiceInternal, MSLogManagerDelegate>

@property NSMutableSet<NSString*> *filteredTypes;
@property NSObject *lock;

@end

// Singleton.
static MSLogFilter *sharedInstance = nil;
static dispatch_once_t onceToken;

// Service name for initialization.
static NSString *const kMSServiceName = @"LogFilter";

// Group id.
static NSString *const kMSGroupId = @"LogFilter";

// User defualts key.
static NSString *const kMSUserDefaultsKey = @"kMSLogFilterTypes";

@implementation MSLogFilter

@synthesize channelConfiguration = _channelConfiguration;

- (instancetype)init {
  if ((self = [super init])) {
    self.filteredTypes = [MSLogFilter readFilteredTypesFromStorage];
    if (!self.filteredTypes) {
      self.filteredTypes = [NSMutableSet new];
    }
    self.lock = [NSObject new];
  }
  return self;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[self alloc] init];
    }
  });
  return sharedInstance;
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];
  MSLogVerbose([MSLogFilter logTag], @"Started Log Filter service.");
}

+ (NSString *)logTag {
  return @"LogFilter";
}

- (NSString *)groupId {
  return kMSGroupId;
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {

    // Add delegate to log manager.
    [self.logManager addDelegate:self];
    MSLogInfo([MSLogFilter logTag], @"Log Filter service has been enabled.");
  } else {
    [self.logManager removeDelegate:self];
      MSLogInfo([MSLogFilter logTag], @"Log Filter service has been disabled.");
  }
}

#pragma mark - Service methods

+ (void)filterLogType:(NSString *)logType {
  [sharedInstance filterLogType:logType];
}

+ (void)unfilterLogType:(NSString *)logType {
  [sharedInstance unfilterLogType:logType];
}

+ (BOOL)isFilteringLogType:(NSString *)logType {
  return [sharedInstance isFilteringLogType:logType];
}

- (void)filterLogType:(NSString *)logType {
  @synchronized(self.lock) {
    if ([self.filteredTypes containsObject:logType]) {
      MSLogInfo([MSLogFilter logTag], @"Already filtering logs of type '%@'.", logType);
    }
    [self.filteredTypes addObject:logType];
    MSLogInfo([MSLogFilter logTag], @"Starting to filter logs of type '%@'.", logType);
    [MSLogFilter storeFilteredTypes:self.filteredTypes];
  }
}

- (void)unfilterLogType:(NSString *)logType {
  @synchronized(self.lock) {
    if (![self.filteredTypes containsObject:logType]) {
      MSLogInfo([MSLogFilter logTag], @"Already not filtering logs of type '%@'.", logType);
    }
    [self.filteredTypes removeObject:logType];
    MSLogInfo([MSLogFilter logTag], @"Stopping to filter logs of type '%@'.", logType);
    [MSLogFilter storeFilteredTypes:self.filteredTypes];
  }
}

- (BOOL)isFilteringLogType:(NSString *)logType {
  @synchronized(self.lock) {
    return [self.filteredTypes containsObject:logType];
  }
}

#pragma mark - Log Manager Delegate

- (BOOL)shouldFilterLog:(id<MSLog>)log {
  // No need to check enabled state here because delegate is added/removed upon changing enabled state.

  @synchronized(self.lock) {
    if (![self isFilteringLogType:log.type]) {
      return NO;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-YYYY HH:mm:ss"];
    NSString *logTimestampString = [dateFormatter stringFromDate:log.timestamp];
    MSLogInfo([MSLogFilter logTag], @"Filtering out a log. Details:\n\tLog Type = %@\n\tLog Timestamp = %@\n\tLog SID = %@", log.type, logTimestampString, log.sid);
    return YES;
  }
}

#pragma mark - Helper

+ (void)storeFilteredTypes:(NSMutableSet*)filteredTypes {
  NSArray *filteredTypesArray = [filteredTypes allObjects];
  [[NSUserDefaults standardUserDefaults] setObject:filteredTypesArray forKey:kMSUserDefaultsKey];
}

+ (NSMutableSet*)readFilteredTypesFromStorage {
  NSArray *filteredTypesArray = [[NSUserDefaults standardUserDefaults] objectForKey:kMSUserDefaultsKey];
  if (!filteredTypesArray) {
    return nil;
  }
  return [NSMutableSet setWithArray:filteredTypesArray];
}

@end
