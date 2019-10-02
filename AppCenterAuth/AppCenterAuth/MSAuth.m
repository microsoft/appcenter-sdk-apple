// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSALAccount.h"
#import "MSALAccountId.h"
#import "MSALAuthority.h"
#import "MSALB2CAuthority.h"
#import "MSALError.h"
#import "MSALLoggerConfig.h"
#import "MSALResult.h"
#import "MSALTenantProfile.h"
#import "MSAppCenterInternal.h"
#import "MSAuthConfig.h"
#import "MSAuthConfigIngestion.h"
#import "MSAuthConstants.h"
#import "MSAuthErrors.h"
#import "MSAuthPrivate.h"
#import "MSAuthTokenContext.h"
#import "MSChannelUnitConfiguration.h"
#import "MSConstants+Internal.h"
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

@implementation MSAuth

@synthesize channelUnitConfiguration = _channelUnitConfiguration;
@synthesize clientApplication = _clientApplication;

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
  if ([self checkURLSchemeRegistered:[NSString stringWithFormat:kMSMSALCustomSchemeFormat, appSecret]]) {

    // Setup MSAL Logging.
    MSALGlobalConfig.loggerConfig.logLevel = MSALLogLevelVerbose;
    @try {
      [MSALGlobalConfig.loggerConfig setLogCallback:^(MSALLogLevel level, NSString *message, BOOL containsPII) {
        if (!containsPII) {
          if (level == MSALLogLevelVerbose) {
            MSLogVerbose([MSAuth logTag], @"%@", message);
          } else if (level == MSALLogLevelInfo) {
            MSLogInfo([MSAuth logTag], @"%@", message);
          } else if (level == MSALLogLevelWarning) {
            MSLogWarning([MSAuth logTag], @"%@", message);
          } else if (level == MSALLogLevelError) {
            MSLogError([MSAuth logTag], @"%@", message);
          }
        }
      }];
    } @catch (NSString *exception) {
      MSLogWarning([MSAuth logTag], @"Enabling MSAL logging failed with exception: %@", exception);
    }

    // Start the service.
    [[MSAuthTokenContext sharedInstance] preventResetAuthTokenAfterStart];
    [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
    MSLogVerbose([MSAuth logTag], @"Started Auth service.");
  } else {
    MSLogError([MSAuth logTag], @"Failed to start Auth service: Custom URL Scheme for Auth not found.");
  }
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

    // Listen to network events.
    [MS_NOTIFICATION_CENTER addObserver:self selector:@selector(networkStateChanged:) name:kMSReachabilityChangedNotification object:nil];

    // Read Auth config file.
    NSString *eTag = nil;
    if ([self loadConfigurationFromCache]) {
      [self configAuthenticationClient];
      eTag = [MS_USER_DEFAULTS objectForKey:kMSAuthETagKey];
    } else {
      self.signInShouldWaitForConfig = YES;
    }

    // Download auth config.
    [self downloadConfigurationWithETag:eTag];
    MSLogInfo([MSAuth logTag], @"Auth service has been enabled.");
  } else {
#if TARGET_OS_IOS
    [[MSAppDelegateForwarder sharedInstance] removeDelegate:self.appDelegate];
#endif
    [[MSAuthTokenContext sharedInstance] removeDelegate:self];
    [MS_NOTIFICATION_CENTER removeObserver:self];
    [self clearAuthData];
    self.clientApplication = nil;
    [self clearConfigurationCache];
    self.ingestion = nil;
    [self cancelPendingOperationsWithErrorCode:MSACAuthErrorServiceDisabled message:@"Auth is disabled."];
    self.signInShouldWaitForConfig = NO;
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
  @synchronized([MSAuth sharedInstance]) {
    if ([[MSAuth sharedInstance] canBeUsed] && [[MSAuth sharedInstance] isEnabled]) {
      [[MSAuth sharedInstance] signInWithCompletionHandler:completionHandler];
    } else {
      [[MSAuth sharedInstance] callCompletionHandler:completionHandler
                                       withErrorCode:MSACAuthErrorServiceDisabled
                                             message:@"Auth is disabled."];
    }
  }
}

+ (void)signOut {
  [[MSAuth sharedInstance] signOut];
}

- (void)signInWithCompletionHandler:(MSSignInCompletionHandler _Nullable)completionHandler {
  if (self.signInCompletionHandler) {
    MSLogError([MSAuth logTag], @"signIn already in progress.");
    [self callCompletionHandler:completionHandler
                  withErrorCode:MSACAuthErrorPreviousSignInRequestInProgress
                        message:@"signIn already in progress."];
    return;
  }
  if (self.refreshCompletionHandler) {
    [self callCompletionHandler:self.refreshCompletionHandler
                  withErrorCode:MSACAuthErrorInterruptedByAnotherOperation
                        message:@"Interrupted by signIn operation."];
    self.refreshCompletionHandler = nil;
  }
  if ([[MS_Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
    [self callCompletionHandler:completionHandler
                  withErrorCode:MSACAuthErrorNoConnection
                        message:@"User sign-in failed. Internet connection is down."];
    return;
  }
  if ((self.clientApplication == nil || self.authConfig == nil) && !self.signInShouldWaitForConfig) {
    [self callCompletionHandler:completionHandler
                  withErrorCode:MSACAuthErrorSignInNotConfigured
                        message:@"'signIn called while not configured."];
    return;
  }
  __weak typeof(self) weakSelf = self;
  self.signInCompletionHandler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    typeof(self) strongSelf = weakSelf;
    @synchronized(strongSelf) {
      strongSelf.signInCompletionHandler = nil;
    }
    if (completionHandler) {
      completionHandler(userInformation, error);
    }
  };

  // At this point if there is no config set / no cached config we must wait for the config to be downloaded before signing in.
  if (self.signInShouldWaitForConfig) {
    MSLogDebug([MSAppCenter logTag], @"Downloading configuration in process. Waiting for it before sign-in.");
  } else {
    [self selectSignInTypeAndSignIn];
  }
}

- (void)selectSignInTypeAndSignIn {
  NSString *accountId = [[MSAuthTokenContext sharedInstance] accountId];
  MSALAccount *account = [self retrieveAccountWithAccountId:accountId];
  if (account) {
    [self acquireTokenSilentlyWithMSALAccount:account
                                   uiFallback:YES
                  keyPathForCompletionHandler:NSStringFromSelector(@selector(signInCompletionHandler))];
  } else {
    [self acquireTokenInteractivelyWithKeyPathForCompletionHandler:NSStringFromSelector(@selector(signInCompletionHandler))];
  }
}

+ (void)setConfigUrl:(NSString *)configUrl {
  [MSAuth sharedInstance].configUrl = configUrl;
}

- (void)callCompletionHandler:(MSAcquireTokenCompletionHandler _Nullable)completionHandler
                withErrorCode:(NSInteger)errorCode
                      message:(NSString *)errorMessage {
  if (completionHandler) {
    NSError *error =
        [[NSError alloc] initWithDomain:kMSACAuthErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
    completionHandler(nil, error);
  }
}

- (void)cancelPendingOperationsWithErrorCode:(NSInteger)errorCode message:(NSString *)message {
  [self callCompletionHandler:self.signInCompletionHandler withErrorCode:errorCode message:message];
  [self callCompletionHandler:self.refreshCompletionHandler withErrorCode:errorCode message:message];
  self.accountIdToRefresh = nil;
}

- (void)signOut {
  @synchronized(self) {
    if (![self canBeUsed]) {
      return;
    }
    [self cancelPendingOperationsWithErrorCode:MSACAuthErrorInterruptedByAnotherOperation message:@"User canceled sign-in."];
    if ([self clearAuthData]) {
      MSLogInfo([MSAuth logTag], @"User sign-out succeeded.");
    }
  }
}

#pragma mark - Private methods

- (BOOL)checkURLSchemeRegistered:(NSString *)urlScheme {
  NSArray *schemes;
  NSString *typeRole;
  NSArray *types = [MS_APP_MAIN_BUNDLE objectForInfoDictionaryKey:kMSCFBundleURLTypes];
  for (NSDictionary *urlType in types) {
    schemes = urlType[kMSCFBundleURLSchemes];
    typeRole = urlType[kMSCFBundleTypeRole];
    for (NSString *scheme in schemes) {
      if ([scheme isEqualToString:urlScheme] && [typeRole isEqualToString:kMSURLTypeRoleEditor]) {
        return YES;
      }
    }
  }
  return NO;
}

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
            @synchronized(self) {
              BOOL continueSignIn = self.signInCompletionHandler && !self.clientApplication;
              self.signInShouldWaitForConfig = NO;
              MSAuthConfig *config = nil;
              if (response.statusCode == MSHTTPCodesNo304NotModified) {
                MSLogInfo([MSAuth logTag], @"Auth config hasn't changed.");

                // Error case, there is no cached config even though the server thinks we have a valid configuration.
                if (!self.authConfig) {
                  [self callCompletionHandler:self.signInCompletionHandler
                                withErrorCode:MSACAuthErrorSignInConfigNotValid
                                      message:@"There was no auth config but the server returned 304 (not modified)."];
                }
              } else if (response.statusCode == MSHTTPCodesNo200OK) {
                config = [self deserializeData:data];
                if ([config isValid]) {
                  NSURL *configUrl =
                      [MSUtility createFileAtPathComponent:[self authConfigFilePath] withData:data atomically:YES forceOverwrite:YES];

                  // Store eTag only when the configuration file is created successfully.
                  if (configUrl) {
                    NSString *newETag = [MSHttpIngestion eTagFromResponse:response];
                    if (newETag) {
                      [MS_USER_DEFAULTS setObject:newETag forKey:kMSAuthETagKey];
                    }
                  } else {
                    MSLogWarning([MSAuth logTag], @"Couldn't create Auth config file.");
                  }
                  self.authConfig = config;

                  // Reinitialize client application.
                  [self configAuthenticationClient];
                  if (continueSignIn) {
                    [self selectSignInTypeAndSignIn];
                  }
                } else {
                  MSLogError([MSAuth logTag], @"Downloaded auth config is not valid.");
                  [self callCompletionHandler:self.signInCompletionHandler
                                withErrorCode:MSACAuthErrorSignInConfigNotValid
                                      message:@"Downloaded auth config is not valid."];
                }
              } else {
                MSLogError([MSAuth logTag], @"Failed to download auth config. Status code received: %ld", (long)response.statusCode);
                [self callCompletionHandler:self.signInCompletionHandler
                              withErrorCode:MSACAuthErrorSignInDownloadConfigFailed
                                    message:[NSString stringWithFormat:@"Failed to download auth config. Status code received: %ld",
                                                                       (long)response.statusCode]];
              }
            }
          }];
}

- (void)configAuthenticationClient {

  // Init MSAL client application.
  NSError *error;
  MSALAuthority *auth = [MSALAuthority authorityWithURL:(NSURL * __nonnull)self.authConfig.authorities[0].authorityUrl error:nil];
  MSALPublicClientApplicationConfig *config =
      [[MSALPublicClientApplicationConfig alloc] initWithClientId:(NSString * __nonnull)self.authConfig.clientId
                                                      redirectUri:self.authConfig.redirectUri
                                                        authority:auth];
  if (!auth) {
    MSLogError([MSAuth logTag], @"Auth config doesn't contain a valid default %@ authority.", self.authConfig.authorities[0].type);
    return;
  }
  config.knownAuthorities = @[ auth ];
  self.clientApplication = [[MSALPublicClientApplication alloc] initWithConfiguration:config error:&error];
  if (error != nil) {
    MSLogError([MSAuth logTag], @"Failed to initialize client application: %@", error.localizedDescription);
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

- (void)acquireTokenSilentlyWithMSALAccount:(MSALAccount *)account
                                 uiFallback:(BOOL)uiFallback
                keyPathForCompletionHandler:(NSString *)completionHandlerKeyPath {
  __weak typeof(self) weakSelf = self;

// FIXME This is a workaround for initial iOS 13 support.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  [self.clientApplication
      acquireTokenSilentForScopes:@[ (NSString * __nonnull)self.authConfig.authScope ]
                          account:account
                  completionBlock:^(MSALResult *result, NSError *error) {
                    typeof(self) strongSelf = weakSelf;
                    MSAcquireTokenCompletionHandler handler = [strongSelf valueForKey:completionHandlerKeyPath];
                    if (!handler) {
                      MSLogDebug([MSAuth logTag], @"Silent acquisition has been interrupted. Ignoring the result.");
                      return;
                    }
                    if (error) {
                      NSString *errorMessage =
                          [NSString stringWithFormat:@"Silent acquisition of token failed with error: %@.", error.localizedDescription];
                      if ([error.domain isEqual:MSALErrorDomain] && error.code == MSALErrorInteractionRequired) {
                        if (uiFallback) {
                          MSLogInfo([MSAuth logTag], @"%@ Triggering interactive acquisition.", errorMessage);
                          [strongSelf acquireTokenInteractivelyWithKeyPathForCompletionHandler:completionHandlerKeyPath];
                          return;
                        } else {
                          MSLogError([MSAuth logTag], @"%@ But interactive acquisition fallback is not allowed here.", errorMessage);
                        }
                      } else {
                        MSLogError([MSAuth logTag], @"%@", errorMessage);
                      }
                      [[MSAuthTokenContext sharedInstance] setAuthToken:nil withAccountId:nil expiresOn:nil];
                      handler(nil, error);
                    } else {
                      NSString *accountId = result.account.identifier;
                      [[MSAuthTokenContext sharedInstance] setAuthToken:result.idToken withAccountId:accountId expiresOn:result.expiresOn];
                      MSLogInfo([MSAuth logTag], @"Silent acquisition of token succeeded.");
                      MSUserInformation *userInformation = [[MSUserInformation alloc] initWithAccountId:result.tenantProfile.identifier
                                                                                            accessToken:result.accessToken
                                                                                                idToken:result.idToken];
                      handler(userInformation, nil);
                    }
                  }];
#pragma clang diagnostic pop
}

- (void)acquireTokenInteractivelyWithKeyPathForCompletionHandler:(NSString *)completionHandlerKeyPath {
  __weak typeof(self) weakSelf = self;

// FIXME This is a workaround for initial iOS 13 support.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  [self.clientApplication
      acquireTokenForScopes:@[ (NSString * __nonnull)self.authConfig.authScope ]
                  loginHint:nil
                 promptType:MSALPromptTypeSelectAccount
       extraQueryParameters:nil
            completionBlock:^(MSALResult *result, NSError *error) {
              typeof(self) strongSelf = weakSelf;
              MSAcquireTokenCompletionHandler handler = [strongSelf valueForKey:completionHandlerKeyPath];
              if (!handler) {
                MSLogDebug([MSAuth logTag], @"Sign-in has been interrupted. Ignoring the result.");
                return;
              }
              if (error) {
                [[MSAuthTokenContext sharedInstance] setAuthToken:nil withAccountId:nil expiresOn:nil];
                if ([error.domain isEqual:MSALErrorDomain] && error.code == MSALErrorUserCanceled) {
                  MSLogWarning([MSAuth logTag], @"User canceled sign-in.");
                } else {
                  MSLogError([MSAuth logTag], @"User sign-in failed. Error: %@", error);
                }
                handler(nil, error);
              } else {
                NSString *accountId = result.account.identifier;
                [[MSAuthTokenContext sharedInstance] setAuthToken:result.idToken withAccountId:accountId expiresOn:result.expiresOn];
                MSLogInfo([MSAuth logTag], @"User sign-in succeeded.");
                MSUserInformation *userInformation = [[MSUserInformation alloc] initWithAccountId:result.tenantProfile.identifier
                                                                                      accessToken:result.accessToken
                                                                                          idToken:result.idToken];
                handler(userInformation, nil);
              }
            }];
#pragma clang diagnostic pop
}

- (MSALAccount *)retrieveAccountWithAccountId:(NSString *)accountId {
  if (!accountId) {
    return nil;
  }
  NSError *error;
  MSALAccount *account = [self.clientApplication accountForIdentifier:accountId error:&error];
  if (error) {
    MSLogWarning([MSAuth logTag], @"Could not get an MSALAccount object for account identifier:%@. Error: %@", accountId, error);
  }
  return account;
}

- (void)refreshTokenForAccountId:(NSString *)accountId withNetworkConnected:(BOOL)networkConnected {
  @synchronized(self) {
    if (self.signInCompletionHandler) {
      MSLogDebug([MSAuth logTag], @"Failed to refresh token: sign-in already in progress.");
      return;
    }
    if (self.refreshCompletionHandler) {
      MSLogDebug([MSAuth logTag], @"Token refresh already in progress. Skip this refresh request.");
      return;
    }
    if (!networkConnected) {
      MSLogDebug([MSAuth logTag], @"Network not connected. The token will be refreshed after coming back online.");
      self.accountIdToRefresh = accountId;
      return;
    }
    if (!self.clientApplication) {
      MSLogWarning([MSAuth logTag], @"MSAL client is not configured. Signing out.");
      [self signOut];
      return;
    }
    MSALAccount *account = [self retrieveAccountWithAccountId:accountId];
    if (account) {
      __weak typeof(self) weakSelf = self;
      self.refreshCompletionHandler = ^(MSUserInformation *_Nullable __unused userInformation, NSError *_Nullable __unused error) {
        typeof(self) strongSelf = weakSelf;
        @synchronized(strongSelf) {
          strongSelf.refreshCompletionHandler = nil;
        }
      };
      [self acquireTokenSilentlyWithMSALAccount:account
                                     uiFallback:NO
                    keyPathForCompletionHandler:NSStringFromSelector(@selector(refreshCompletionHandler))];
    } else {

      // If account not found, start an anonymous session to avoid deadlock.
      MSLogWarning([MSAuth logTag],
                   @"Could not get account for the accountId of the token that needs to be refreshed. Starting anonymous session.");
      [[MSAuthTokenContext sharedInstance] setAuthToken:nil withAccountId:nil expiresOn:nil];
    }
  }
}

#pragma mark - MSAuthTokenContextDelegate

- (void)authTokenContext:(MSAuthTokenContext *)__unused authTokenContext refreshAuthTokenForAccountId:(nullable NSString *)accountId {
  BOOL networkConnected = [[MS_Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable;
  [self refreshTokenForAccountId:(NSString *)accountId withNetworkConnected:networkConnected];
}

#pragma mark - Reachability

- (void)networkStateChanged:(NSNotificationCenter *)__unused notification {
  BOOL networkConnected = [[MS_Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable;
  if (networkConnected && self.accountIdToRefresh) {
    NSString *accountId = self.accountIdToRefresh;
    self.accountIdToRefresh = nil;
    [self refreshTokenForAccountId:accountId withNetworkConnected:YES];
  }
}

@end
