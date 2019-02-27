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
@property(nullable, nonatomic, copy) NSString *authToken;

/**
 * The last value of user account id.
 */
@property(nullable, nonatomic, copy) NSString *homeAccountId;

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

- (nullable NSString *)authToken {
  @synchronized(self) {
    return _authToken;
  }
}

- (void)setAuthToken:(NSString *)authToken withAccountId:(NSString *)accountId {
  NSArray *synchronizedDelegates;
  BOOL isNewUser = NO;
  @synchronized(self) {
    self.authToken = authToken;
    isNewUser = self.homeAccountId == nil || ![self.homeAccountId isEqualToString:accountId];
    self.homeAccountId = accountId;

    // Don't invoke the delegate while locking; it might be locking too and deadlock ourselves.
    synchronizedDelegates = [self.delegates allObjects];
  }
  for (id<MSAuthTokenContextDelegate> delegate in synchronizedDelegates) {
    if ([delegate respondsToSelector:@selector(authTokenContext:didReceiveAuthToken:)]) {
      [delegate authTokenContext:self didReceiveAuthToken:authToken];
    }
    if (isNewUser && [delegate respondsToSelector:@selector(authTokenContext:didUpdateUserWithAuthToken:)]) {
      [delegate authTokenContext:self didUpdateUserWithAuthToken:authToken];
    }
  }
}

- (void)clearAuthToken {
  NSArray *synchronizedDelegates;
  @synchronized(self) {
    self.authToken = nil;
    self.homeAccountId = nil;

    // Don't invoke the delegate while locking; it might be locking too and deadlock ourselves.
    synchronizedDelegates = [self.delegates allObjects];
  }
  for (id<MSAuthTokenContextDelegate> delegate in synchronizedDelegates) {
    if ([delegate respondsToSelector:@selector(authTokenContext:didReceiveAuthToken:)]) {
      [delegate authTokenContext:self didReceiveAuthToken:nil];
    }
    if ([delegate respondsToSelector:@selector(authTokenContext:didUpdateUserWithAuthToken:)]) {
      [delegate authTokenContext:self didUpdateUserWithAuthToken:nil];
    }
  }
}

- (void)addDelegate:(id<MSAuthTokenContextDelegate>)delegate {
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
