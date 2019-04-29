// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSALAccount.h"
#import "MSALAccountId.h"
#import "MSALAuthority.h"
#import "MSALError.h"
#import "MSALResult.h"
#import "MSAppCenterInternal.h"
#import "MSAuthConfig.h"
#import "MSAuthConfigIngestion.h"
#import "MSAuthConstants.h"
#import "MSAuthErrors.h"
#import "MSAuthPrivate.h"
#import "MSAuthTokenContext.h"
#import "MSChannelUnitConfiguration.h"
#import "MSConstants+Internal.h"
#import "MSServiceAbstractProtected.h"
#import "MSUserInformation.h"
#import "MSUtility+File.h"

#if TARGET_OS_IOS
#import "MSAppDelegateForwarder.h"
#import "MSAuthAppDelegate.h"
#endif

// Service name for initialization.
static NSString *const kMSServiceName = @"Auth";

// The group Id for auth.
static NSString *const kMSGroupId = @"Auth";

// Singleton
static MSAuth *sharedInstance = nil;
static dispatch_once_t onceToken;
static boolean_t delayedSignIn = NO;

@implementation MSAuth

@synthesize channelUnitConfiguration = _channelUnitConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _channelUnitConfiguration = [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];

#if TARGET_OS_IOS
    _appDelegate = [MSAuthAppDelegate new];
#endif
    _configUrl = kMSAuthDefaultBaseURL;
    [MSUtility createDirectoryForPathComponent:kMSAuthPathComponent];
  }
  return self;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[MSAuth alloc] init];
    }
  });
  return sharedInstance;
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  [[MSAuthTokenContext sharedInstance] preventResetAuthTokenAfterStart];
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
  MSLogVerbose([MSAuth logTag], @"Started Auth service.");
}

+ (NSString *)logTag {
  return @"AppCenterAuth";
}

- (NSString *)groupId {
  return kMSGroupId;
}

#pragma mark - MSServiceAbstract

- (void)setEnabled:(BOOL)isEnabled {
  [super setEnabled:isEnabled];
}

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {
#if TARGET_OS_IOS
    [[MSAppDelegateForwarder sharedInstance] addDelegate:self.appDelegate];
#endif
    [[MSAuthTokenContext sharedInstance] addDelegate:self];

    // Read Auth config file.
    NSString *eTag = nil;
    if ([self loadConfigurationFromCache]) {
      [self configAuthenticationClient];
      eTag = [MS_USER_DEFAULTS objectForKey:kMSAuthETagKey];
    }

    // Download auth config.
    [self downloadConfigurationWithETag:eTag];
    MSLogInfo([MSAuth logTag], @"Auth service has been enabled.");
  } else {
#if TARGET_OS_IOS
    [[MSAppDelegateForwarder sharedInstance] removeDelegate:self.appDelegate];
#endif
    [[MSAuthTokenContext sharedInstance] removeDelegate:self];
    [self clearAuthData];
    self.clientApplication = nil;
    [self clearConfigurationCache];
    self.ingestion = nil;
    NSError *error = [[NSError alloc] initWithDomain:kMSACAuthErrorDomain
                                                code:MSACAuthErrorServiceDisabled
                                            userInfo:@{NSLocalizedDescriptionKey : @"Auth is disabled."}];
    [self completeAcquireTokenRequestForResult:nil withError:error];
    delayedSignIn = NO;
    MSLogInfo([MSAuth logTag], @"Auth service has been disabled.");
  }
}

#pragma mark - Service methods

+ (void)resetSharedInstance {

  // Resets the once_token so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
}

#if TARGET_OS_IOS
+ (BOOL)openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  NSString *sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey];
  if (!sourceApplication) {
    MSLogError([MSAuth logTag], @"sourceApplication is not provided in openURL options.");
    return NO;
  }
  return [MSALPublicClientApplication handleMSALResponse:url sourceApplication:sourceApplication];
}
#endif

+ (void)signInWithCompletionHandler:(MSSignInCompletionHandler _Nullable)completionHandler {

  // We allow completion handler to be optional but we need a non nil one to track operation progress internally.
  if (!completionHandler) {
    completionHandler = ^(MSUserInformation *_Nullable __unused userInformation, NSError *_Nullable __unused error) {
    };
  }
  @synchronized([MSAuth sharedInstance]) {
    if ([[MSAuth sharedInstance] canBeUsed] && [[MSAuth sharedInstance] isEnabled]) {
      if ([MSAuth sharedInstance].signInCompletionHandler) {
        MSLogError([MSAuth logTag], @"signIn already in progress.");
        NSError *error = [[NSError alloc] initWithDomain:kMSACAuthErrorDomain
                                                    code:MSACAuthErrorPreviousSignInRequestInProgress
                                                userInfo:@{NSLocalizedDescriptionKey : @"signIn already in progress."}];
        completionHandler(nil, error);
        return;
      }
      [MSAuth sharedInstance].signInCompletionHandler = completionHandler;
      [[MSAuth sharedInstance] signIn];
    } else {
      NSError *error = [[NSError alloc] initWithDomain:kMSACAuthErrorDomain
                                                  code:MSACAuthErrorServiceDisabled
                                              userInfo:@{NSLocalizedDescriptionKey : @"Auth is disabled."}];
      completionHandler(nil, error);
    }
  }
}

+ (void)signOut {
  [[MSAuth sharedInstance] signOut];
}

- (void)signIn {
  if ([[MS_Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
    [self completeSignInWithErrorCode:MSACAuthErrorSignInWhenNoConnection andMessage:@"User sign-in failed. Internet connection is down."];
    return;
  }
  if (self.clientApplication == nil || self.authConfig == nil) {
    delayedSignIn = YES;
    return;
  }
  [self continueSignIn];
}

- (void)continueSignIn {
  NSString *accountId = [[MSAuthTokenContext sharedInstance] accountId];
  MSALAccount *account = [self retrieveAccountWithAccountId:accountId];
  if (account) {
    [self acquireTokenSilentlyWithMSALAccount:account];
  } else {
    [self acquireTokenInteractively];
  }
}

+ (void)setConfigUrl:(NSString *)configUrl {
  [MSAuth sharedInstance].configUrl = configUrl;
}

- (void)completeSignInWithErrorCode:(NSInteger)errorCode andMessage:(NSString *)errorMessage {
  if (!self.signInCompletionHandler) {
    return;
  }
  NSError *error = [[NSError alloc] initWithDomain:kMSACAuthErrorDomain
                                              code:errorCode
                                          userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
  self.signInCompletionHandler(nil, error);
  self.signInCompletionHandler = nil;
}

- (void)signOut {
  @synchronized(self) {
    if (![self canBeUsed]) {
      return;
    }
    if ([self clearAuthData]) {
      MSLogInfo([MSAuth logTag], @"User sign-out succeeded.");
    }
  }
}

#pragma mark - Private methods

- (NSString *)authConfigFilePath {
  return [NSString stringWithFormat:@"%@/%@", kMSAuthPathComponent, kMSAuthConfigFilename];
}

- (BOOL)loadConfigurationFromCache {
  NSData *configData = [MSUtility loadDataForPathComponent:[self authConfigFilePath]];
  if (configData == nil) {
    MSLogWarning([MSAuth logTag], @"Auth config file doesn't exist.");
  } else {
    MSAuthConfig *config = [self deserializeData:configData];
    if ([config isValid]) {
      self.authConfig = config;
      return YES;
    }
    [self clearConfigurationCache];
    self.authConfig = nil;
    MSLogError([MSAuth logTag], @"Auth config file is not valid.");
  }
  return NO;
}

- (MSAuthConfigIngestion *)ingestion {
  if (!_ingestion) {
    _ingestion = [[MSAuthConfigIngestion alloc] initWithBaseUrl:self.configUrl appSecret:self.appSecret];
  }
  return _ingestion;
}

- (void)downloadConfigurationWithETag:(nullable NSString *)eTag {

  // Download configuration.
  [self.ingestion sendAsync:nil
                       eTag:eTag
          completionHandler:^(__unused NSString *callId, NSHTTPURLResponse *response, NSData *data, __unused NSError *error) {
            MSAuthConfig *config = nil;
            if (response.statusCode == MSHTTPCodesNo304NotModified) {
              MSLogInfo([MSAuth logTag], @"Auth config hasn't changed.");
            } else if (response.statusCode == MSHTTPCodesNo200OK) {
              config = [self deserializeData:data];
              if ([config isValid]) {
                NSURL *configUrl = [MSUtility createFileAtPathComponent:[self authConfigFilePath]
                                                               withData:data
                                                             atomically:YES
                                                         forceOverwrite:YES];

                // Store eTag only when the configuration file is created successfully.
                if (configUrl) {
                  NSString *newETag = [MSHttpIngestion eTagFromResponse:response];
                  if (newETag) {
                    [MS_USER_DEFAULTS setObject:newETag forKey:kMSAuthETagKey];
                  }
                } else {
                  MSLogWarning([MSAuth logTag], @"Couldn't create Auth config file.");
                }
                @synchronized(self) {
                  self.authConfig = config;

                  // Reinitialize client application.
                  [self configAuthenticationClient];
                }
                if (delayedSignIn) {
                  delayedSignIn = NO;
                  [self continueSignIn];
                }
              } else {
                if (delayedSignIn) {
                  delayedSignIn = NO;
                  [self completeSignInWithErrorCode:MSACAuthErrorSignInConfigNotValid andMessage:@"Downloaded auth config is not valid."];
                }
              }
            } else {

              if (delayedSignIn) {
                delayedSignIn = NO;
                [self completeSignInWithErrorCode:MSACAuthErrorSignInDownloadConfigFailed
                                       andMessage:[NSString stringWithFormat:@"Failed to download auth config. Status code received: %ld",
                                                                             (long)response.statusCode]];
              }
            }
          }];
}

- (void)configAuthenticationClient {

  // Init MSAL client application.
  NSError *error;
  MSALAuthority *auth = [MSALAuthority authorityWithURL:(NSURL * __nonnull) self.authConfig.authorities[0].authorityUrl error:nil];
  MSALPublicClientApplicationConfig *config =
      [[MSALPublicClientApplicationConfig alloc] initWithClientId:(NSString * __nonnull) self.authConfig.clientId
                                                      redirectUri:self.authConfig.redirectUri
                                                        authority:auth];
  if (!auth) {
    MSLogError([MSAuth logTag], @"Auth config doesn't contain a valid authority.");
    return;
  }
  config.knownAuthorities = @[ auth ];
  self.clientApplication = [[MSALPublicClientApplication alloc] initWithConfiguration:config error:&error];
  if (error != nil) {
    MSLogError([MSAuth logTag], @"Failed to initialize client application.");
  }
}

- (void)clearConfigurationCache {
  [MSUtility deleteItemForPathComponent:[self authConfigFilePath]];
  [MS_USER_DEFAULTS removeObjectForKey:kMSAuthETagKey];
}

- (MSAuthConfig *)deserializeData:(NSData *)data {
  NSError *error;
  MSAuthConfig *config;
  if (data) {
    id dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
      MSLogError([MSAuth logTag], @"Couldn't parse json data: %@", error.localizedDescription);
    } else {
      config = [[MSAuthConfig alloc] initWithDictionary:dictionary];
    }
  }
  return config;
}

- (BOOL)clearAuthData {
  BOOL result = YES;
  if (![self removeAccount]) {
    MSLogWarning([MSAuth logTag], @"Couldn't remove account data.");
    result = NO;
  }
  [[MSAuthTokenContext sharedInstance] setAuthToken:nil withAccountId:nil expiresOn:nil];
  return result;
}

- (BOOL)removeAccount {
  if (!self.clientApplication) {
    return NO;
  }
  NSString *accountId = [[MSAuthTokenContext sharedInstance] accountId];
  MSALAccount *account = [self retrieveAccountWithAccountId:accountId];
  if (account) {
    NSError *error;
    [self.clientApplication removeAccount:account error:&error];
    if (error) {
      MSLogWarning([MSAuth logTag], @"Failed to remove account: %@", error.localizedDescription);
      return NO;
    }
  }
  return YES;
}

- (void)acquireTokenSilentlyWithMSALAccount:(MSALAccount *)account {
  __weak typeof(self) weakSelf = self;
  [self.clientApplication
      acquireTokenSilentForScopes:@[ (NSString * __nonnull) self.authConfig.authScope ]
                          account:account
                  completionBlock:^(MSALResult *result, NSError *e) {
                    typeof(self) strongSelf = weakSelf;
                    if (e) {
                      MSLogWarning([MSAuth logTag],
                                   @"Silent acquisition of token failed with error: %@. Triggering interactive acquisition", e);
                      [strongSelf acquireTokenInteractively];
                    } else {
                      MSALAccountId *accountId = (MSALAccountId * __nonnull) result.account.homeAccountId;
                      [[MSAuthTokenContext sharedInstance] setAuthToken:result.idToken
                                                          withAccountId:accountId.identifier
                                                              expiresOn:result.expiresOn];
                      [strongSelf completeAcquireTokenRequestForResult:result withError:nil];
                      MSLogInfo([MSAuth logTag], @"Silent acquisition of token succeeded.");
                    }
                  }];
}

- (void)acquireTokenInteractively {
  __weak typeof(self) weakSelf = self;
  [self.clientApplication acquireTokenForScopes:@[ (NSString * __nonnull) self.authConfig.authScope ]
                                completionBlock:^(MSALResult *result, NSError *e) {
                                  typeof(self) strongSelf = weakSelf;
                                  if (e) {
                                    [[MSAuthTokenContext sharedInstance] setAuthToken:nil withAccountId:nil expiresOn:nil];
                                    if (e.code == MSALErrorUserCanceled) {
                                      MSLogWarning([MSAuth logTag], @"User canceled sign-in.");
                                    } else {
                                      MSLogError([MSAuth logTag], @"User sign-in failed. Error: %@", e);
                                    }
                                  } else {
                                    MSALAccountId *accountId = (MSALAccountId * __nonnull) result.account.homeAccountId;
                                    [[MSAuthTokenContext sharedInstance] setAuthToken:result.idToken
                                                                        withAccountId:accountId.identifier
                                                                            expiresOn:result.expiresOn];
                                    MSLogInfo([MSAuth logTag], @"User sign-in succeeded.");
                                  }
                                  [strongSelf completeAcquireTokenRequestForResult:result withError:e];
                                }];
}

- (void)completeAcquireTokenRequestForResult:(MSALResult *)result withError:(NSError *)error {
  @synchronized(self) {
    if (!self.signInCompletionHandler) {
      return;
    }
    if (error) {
      self.signInCompletionHandler(nil, error);
    } else {
      MSUserInformation *userInformation = [MSUserInformation new];
      userInformation.accountId = (NSString * __nonnull) result.uniqueId;
      self.signInCompletionHandler(userInformation, nil);
    }
    self.signInCompletionHandler = nil;
  }
}

- (MSALAccount *)retrieveAccountWithAccountId:(NSString *)homeAccountId {
  if (!homeAccountId) {
    return nil;
  }
  NSError *error;
  MSALAccount *account = [self.clientApplication accountForHomeAccountId:homeAccountId error:&error];
  if (error) {
    MSLogWarning([MSAuth logTag], @"Could not get MSALAccount for homeAccountId. Error: %@", error);
  }
  return account;
}

#pragma mark - MSAuthTokenContextDelegate

- (void)authTokenContext:(MSAuthTokenContext *)authTokenContext refreshAuthTokenForAccountId:(nullable NSString *)accountId {
  MSALAccount *account = [self retrieveAccountWithAccountId:accountId];
  if (account) {
    [self acquireTokenSilentlyWithMSALAccount:account];
  } else {

    // If account not found, start an anonymous session to avoid deadlock.
    MSLogWarning([MSAuth logTag],
                 @"Could not get account for the accountId of the token that needs to be refreshed. Starting anonymous session.");
    [authTokenContext setAuthToken:nil withAccountId:nil expiresOn:nil];
  }
}
@end
