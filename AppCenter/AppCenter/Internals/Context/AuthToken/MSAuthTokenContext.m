#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextDelegate.h"

/**
 * Singleton.
 */
static MSAuthTokenContext *sharedInstance;
static dispatch_once_t onceToken;

@interface MSAuthTokenContext ()

/**
 * Authorization token cached value.
 */
@property(nonatomic) NSString *authToken;

/**
 * The last value of user account id.
 */
@property(nonatomic) NSString *lastHomeAccountId;

/**
 * Collection of channel delegates.
 */
@property(nonatomic) NSHashTable<id<MSAuthTokenContextDelegate>> *delegates;

@end

@implementation MSAuthTokenContext

- (instancetype)init {
  self = [super init];
  if (self) {
    _delegates = [NSHashTable new];
  }
  return self;
}

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [MSAuthTokenContext new];
    }
  });
  return sharedInstance;
}

+ (void)resetSharedInstance {
  onceToken = 0;
  sharedInstance = nil;
}

- (NSString *)getAuthToken {
  @synchronized(self) {
    return self.authToken;
  }
}

- (void)setAuthToken:(NSString *_Nonnull)authToken withAccountId:(NSString *_Nonnull)accountId {
  NSArray *synchronizedDelegates;
  BOOL isNewUser = NO;
  @synchronized(self) {
    self.authToken = authToken;
    isNewUser = self.lastHomeAccountId == nil || ![self.lastHomeAccountId isEqualToString:accountId];
    self.lastHomeAccountId = accountId;
    
      // Don't invoke the delegate while locking; it might be locking too and deadlock ourselves.
    synchronizedDelegates = [self.delegates allObjects];
  }
  for (id<MSAuthTokenContextDelegate> delegate in synchronizedDelegates) {
    [delegate authTokenContext:self didReceiveAuthToken:authToken forNewUser:isNewUser];
  }
}

- (void)clearAuthToken {
  NSArray *synchronizedDelegates;
  @synchronized(self) {
    self.authToken = nil;
    self.lastHomeAccountId = nil;
    
    // Don't invoke the delegate while locking; it might be locking too and deadlock ourselves.
    synchronizedDelegates = [self.delegates allObjects];
  }
  for (id<MSAuthTokenContextDelegate> delegate in synchronizedDelegates) {
    [delegate authTokenContext:self didReceiveAuthToken:nil forNewUser:YES];
  }
}

- (void)addDelegate:(id<MSAuthTokenContextDelegate> _Nonnull)delegate {
  @synchronized(self) {
    [self.delegates addObject:delegate];
  }
}

- (void)removeDelegate:(id<MSAuthTokenContextDelegate>)delegate {
  @synchronized(self) {
    [self.delegates removeObject:delegate];
  }
}

@end
