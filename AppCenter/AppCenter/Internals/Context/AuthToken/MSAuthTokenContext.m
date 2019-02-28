#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextPrivate.h"
#import "MSAuthTokenContextDelegate.h"

/**
 * Singleton.
 */
static MSAuthTokenContext *sharedInstance;
static dispatch_once_t onceToken;

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
  [self invokeAuthTokenEvents:synchronizedDelegates withToken:authToken isNewUser:isNewUser];
}

- (void)clearAuthToken {
  NSArray *synchronizedDelegates;
  @synchronized(self) {
    self.authToken = nil;
    self.homeAccountId = nil;

    // Don't invoke the delegate while locking; it might be locking too and deadlock ourselves.
    synchronizedDelegates = [self.delegates allObjects];
  }
  [self invokeAuthTokenEvents:synchronizedDelegates withToken:nil isNewUser:YES];
}

- (void)invokeAuthTokenEvents:(NSArray *)delegates withToken:(NSString *)token isNewUser:(BOOL)newUser {
  for (id<MSAuthTokenContextDelegate> delegate in delegates) {
    if ([delegate respondsToSelector:@selector(authTokenContext:didReceiveAuthToken:)]) {
      [delegate authTokenContext:self didReceiveAuthToken:token];
    }
    if (newUser && [delegate respondsToSelector:@selector(authTokenContext:didUpdateUserWithAuthToken:)]) {
      [delegate authTokenContext:self didUpdateUserWithAuthToken:token];
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
