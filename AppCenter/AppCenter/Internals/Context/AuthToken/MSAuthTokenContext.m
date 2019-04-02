// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSUserInformation.h"

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
 * The last value of user information.
 */
@property(nonatomic, strong) MSUserInformation *homeUser;

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

- (void)setAuthToken:(NSString *)authToken withUserInformation:(MSUserInformation *)userInformation {
  NSArray *synchronizedDelegates;
  BOOL isNewUser = NO;
  @synchronized(self) {
    self.authToken = authToken;
    isNewUser = ![self.homeUser isEqualTo:userInformation];
    if (isNewUser) {
      self.homeUser = userInformation;
    }

    // Don't invoke the delegate while locking; it might be locking too and deadlock ourselves.
    synchronizedDelegates = [self.delegates allObjects];
  }
  for (id<MSAuthTokenContextDelegate> delegate in synchronizedDelegates) {
    if ([delegate respondsToSelector:@selector(authTokenContext:didUpdateAuthToken:)]) {
      [delegate authTokenContext:self didUpdateAuthToken:authToken];
    }
    if (isNewUser && [delegate respondsToSelector:@selector(authTokenContext:didUpdateUserInformation:)]) {
      [delegate authTokenContext:self didUpdateUserInformation:userInformation];
    }
  }
}

- (BOOL)clearAuthToken {
  NSArray *synchronizedDelegates;
  BOOL clearedExistingUser = NO;
  @synchronized(self) {
    if (!self.authToken) {
      return NO;
    } else if (self.homeUser.accountId) {
      clearedExistingUser = YES;
    }
    self.authToken = nil;
    self.homeUser.accountId = nil;

    // Don't invoke the delegate while locking; it might be locking too and deadlock ourselves.
    synchronizedDelegates = [self.delegates allObjects];
  }
  for (id<MSAuthTokenContextDelegate> delegate in synchronizedDelegates) {
    if ([delegate respondsToSelector:@selector(authTokenContext:didUpdateAuthToken:)]) {
      [delegate authTokenContext:self didUpdateAuthToken:nil];
    }
    if (clearedExistingUser && [delegate respondsToSelector:@selector(authTokenContext:didUpdateUserInformation:)]) {
      [delegate authTokenContext:self didUpdateUserInformation:self.homeUser];
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
