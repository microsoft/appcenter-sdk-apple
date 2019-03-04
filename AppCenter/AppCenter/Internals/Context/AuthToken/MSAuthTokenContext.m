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
@property(nullable, atomic, copy) NSString *authToken;

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

- (void)setAuthToken:(NSString *)authToken withAccountId:(NSString *)accountId {
  NSArray *synchronizedDelegates;
  BOOL isNewUser = NO;
  @synchronized(self) {
    self.authToken = authToken;
    isNewUser = ![self.homeAccountId isEqualToString:accountId];
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

- (BOOL)clearAuthToken {
  NSArray *synchronizedDelegates;
  BOOL clearedExistingUser = NO;
  @synchronized(self) {
    if (!self.authToken) {
      return NO;
    } else if (self.homeAccountId) {
      clearedExistingUser = YES;
    }
    self.authToken = nil;
    self.homeAccountId = nil;

    // Don't invoke the delegate while locking; it might be locking too and deadlock ourselves.
    synchronizedDelegates = [self.delegates allObjects];
  }
  for (id<MSAuthTokenContextDelegate> delegate in synchronizedDelegates) {
    if ([delegate respondsToSelector:@selector(authTokenContext:didReceiveAuthToken:)]) {
      [delegate authTokenContext:self didReceiveAuthToken:nil];
    }
    if (clearedExistingUser && [delegate respondsToSelector:@selector(authTokenContext:didUpdateUserWithAuthToken:)]) {
      [delegate authTokenContext:self didUpdateUserWithAuthToken:nil];
    }
  }
  return YES;
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
