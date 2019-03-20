// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSAuthTokenStorage.h"

/**
 * Singleton.
 */
static MSAuthTokenContext *sharedInstance;
static dispatch_once_t onceToken;

@interface MSAuthTokenContext ()

/**
 * Cached authorization token.
 */
@property(nullable, atomic, copy) NSString *authToken;

/**
 * The last value of user account id.
 */
@property(nullable, atomic, copy) NSString *accountId;

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

- (void)setAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId {
  [self.storage saveAuthToken:authToken withAccountId:accountId];
  [self updateAuthToken:authToken withAccountId:accountId];
}

- (void)updateAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId {
  NSArray *synchronizedDelegates;
  BOOL isNewUser = NO;
  @synchronized(self) {
    isNewUser = ![self.accountId isEqual:accountId];
    self.authToken = authToken;
    self.accountId = accountId;

    // Don't invoke the delegate while locking; it might be locking too and deadlock ourselves.
    synchronizedDelegates = [self.delegates allObjects];
  }
  for (id<MSAuthTokenContextDelegate> delegate in synchronizedDelegates) {
    if ([delegate respondsToSelector:@selector(authTokenContext:didSetNewAuthToken:)]) {
      [delegate authTokenContext:self didSetNewAuthToken:authToken];
    }
    if (isNewUser && [delegate respondsToSelector:@selector(authTokenContext:didSetNewAccountIdWithAuthToken:)]) {
      [delegate authTokenContext:self didSetNewAccountIdWithAuthToken:authToken];
    }
  }
}

- (BOOL)clearAuthToken {
  @synchronized(self) {
    if (!self.authToken) {
      return NO;
    }
  }
  [self setAuthToken:nil withAccountId:nil];
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

- (void)cacheAuthToken {
  @synchronized(self) {
    self.authToken = [self.storage retrieveAuthToken];
    self.accountId = [self.storage retrieveAccountId];
  }
}

@end
