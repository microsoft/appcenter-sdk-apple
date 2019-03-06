#import "MSAppCenterInternal.h"
#import "MSAppDelegateForwarder.h"
#import "MSAuthTokenContext.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSConstants+Internal.h"
#import "MSIdentityAppDelegate.h"
#import "MSIdentityConfig.h"
#import "MSIdentityConfigIngestion.h"
#import "MSIdentityPrivate.h"
#import "MSKeychainUtil.h"
#import "MSServiceAbstractProtected.h"
#import "MSUtility+File.h"

// Service name for initialization.
static NSString *const kMSServiceName = @"Identity";

// The group Id for storage.
static NSString *const kMSGroupId = @"Identity";

// The path component of Identity for configuration.
static NSString *const kMSIdentityPathComponent = @"identity";

// The Identity config file name.
static NSString *const kMSIdentityConfigFilename = @"config.json";

// Singleton
static MSIdentity *sharedInstance = nil;
static dispatch_once_t onceToken;

@implementation MSIdentity

@synthesize channelUnitConfiguration = _channelUnitConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _channelUnitConfiguration = [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];
    _appDelegate = [MSIdentityAppDelegate new];
    [MSUtility createDirectoryForPathComponent:kMSIdentityPathComponent];
  }
  return self;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[MSIdentity alloc] init];
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
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
  MSLogVerbose([MSIdentity logTag], @"Started Identity service.");
}

+ (NSString *)logTag {
  return @"AppCenterIdentity";
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
    [self.channelGroup addDelegate:self];
    [[MSAppDelegateForwarder sharedInstance] addDelegate:self.appDelegate];

    // Read Identity config file.
    NSString *eTag = nil;
    if ([self loadConfigurationFromCache]) {
      [self configAuthenticationClient];
      eTag = [MS_USER_DEFAULTS objectForKey:kMSIdentityETagKey];
    }
    NSString *authToken = [self retrieveAuthToken];
    NSString *accountId = [self retrieveAccountId];

    // Only set the auth token if auth token and account id are not nil to avoid triggering callbacks.
    if (authToken && accountId) {
      [[MSAuthTokenContext sharedInstance] setAuthToken:authToken withAccountId:accountId];
    }

    // Download identity configuration.
    [self downloadConfigurationWithETag:eTag];
    MSLogInfo([MSIdentity logTag], @"Identity service has been enabled.");
  } else {
    [[MSAppDelegateForwarder sharedInstance] removeDelegate:self.appDelegate];
    [self clearAuthData];
    self.clientApplication = nil;
    self.signInDelayedAndRetryLater = NO;
    [self clearConfigurationCache];
    [self.channelGroup removeDelegate:self];
    NSError *error = [[NSError alloc] initWithDomain:MSIdentityErrorDomain
                                                code:MSIdentityErrorServiceDisabled
                                            userInfo:@{MSIdentityErrorDescriptionKey : @"Identity is disabled."}];
    [self completeAcquireTokenRequestForResult:nil withError:error];
    MSLogInfo([MSIdentity logTag], @"Identity service has been disabled.");
  }
}

#pragma mark - MSChannelDelegate

- (void)channel:(id<MSChannelProtocol>)channel willSendLog:(id<MSLog>)log {
  (void)channel;
  (void)log;
}

- (void)channel:(id<MSChannelProtocol>)channel didSucceedSendingLog:(id<MSLog>)log {
  (void)channel;
  (void)log;
}

- (void)channel:(id<MSChannelProtocol>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  (void)channel;
  (void)log;
  (void)error;
}

#pragma mark - Service methods

+ (void)resetSharedInstance {

  // Resets the once_token so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
}

+ (BOOL)openURL:(NSURL *)url {
  return [MSALPublicClientApplication handleMSALResponse:url];
}

+ (void)signInWithCompletionHandler:(MSSignInCompletionHandler _Nullable)completionHandler {

  // We allow completion handler to be optional but we need a non nil one to track operation progress internally.
  if (!completionHandler) {
    completionHandler = ^(MSUserInformation *_Nullable __unused userInformation, NSError *_Nullable __unused error) {
    };
  }
  @synchronized([MSIdentity sharedInstance]) {
    if ([[MSIdentity sharedInstance] canBeUsed] && [[MSIdentity sharedInstance] isEnabled]) {
      if ([MSIdentity sharedInstance].signInCompletionHandler) {
        MSLogError([MSIdentity logTag], @"signIn already in progress.");
        NSError *error = [[NSError alloc] initWithDomain:MSIdentityErrorDomain
                                                    code:MSIdentityErrorPreviousSignInRequestInProgress
                                                userInfo:@{MSIdentityErrorDescriptionKey : @"signIn already in progress."}];
        completionHandler(nil, error);
        return;
      }
      [MSIdentity sharedInstance].signInCompletionHandler = completionHandler;
      [[MSIdentity sharedInstance] signIn];
    } else {
      NSError *error = [[NSError alloc] initWithDomain:MSIdentityErrorDomain
                                                  code:MSIdentityErrorServiceDisabled
                                              userInfo:@{MSIdentityErrorDescriptionKey : @"Identity is disabled."}];
      completionHandler(nil, error);
    }
  }
}

+ (void)signOut {
  [[MSIdentity sharedInstance] signOut];
}

- (void)signIn {
  if (self.clientApplication == nil || self.identityConfig == nil) {
    MSLogDebug([MSIdentity logTag], @"signIn is called while it's not configured or not in the foreground, waiting.");
    self.signInDelayedAndRetryLater = YES;
    return;
  }
  self.signInDelayedAndRetryLater = NO;
  MSALAccount *account = [self retrieveAccountWithAccountId:[self retrieveAccountId]];
  if (account) {
    [self acquireTokenSilentlyWithMSALAccount:account];
  } else {
    [self acquireTokenInteractively];
  }
}

- (void)signOut {
  @synchronized(self) {
    if (![self canBeUsed]) {
      return;
    }
    self.signInDelayedAndRetryLater = NO;
    if ([self clearAuthData]) {
      MSLogInfo([MSIdentity logTag], @"User sign-out succeeded.");
    }
  }
}

#pragma mark - Private methods

- (NSString *)identityConfigFilePath {
  return [NSString stringWithFormat:@"%@/%@", kMSIdentityPathComponent, kMSIdentityConfigFilename];
}

- (BOOL)loadConfigurationFromCache {
  NSData *configData = [MSUtility loadDataForPathComponent:[self identityConfigFilePath]];
  if (configData == nil) {
    MSLogWarning([MSIdentity logTag], @"Identity config file doesn't exist.");
  } else {
    MSIdentityConfig *config = [self deserializeData:configData];
    if ([config isValid]) {
      self.identityConfig = config;
      return YES;
    }
    [self clearConfigurationCache];
    self.identityConfig = nil;
    MSLogError([MSIdentity logTag], @"Identity config file is not valid.");
  }
  return NO;
}

- (void)downloadConfigurationWithETag:(nullable NSString *)eTag {

  // Download configuration.
  MSIdentityConfigIngestion *ingestion =
      [[MSIdentityConfigIngestion alloc] initWithBaseUrl:@"https://mobilecentersdkdev.blob.core.windows.net" appSecret:self.appSecret];
  [ingestion sendAsync:nil
                   eTag:eTag
      completionHandler:^(__unused NSString *callId, NSHTTPURLResponse *response, NSData *data, __unused NSError *error) {
        MSIdentityConfig *config = nil;
        if (response.statusCode == MSHTTPCodesNo304NotModified) {
          MSLogInfo([MSIdentity logTag], @"Identity configuration hasn't changed.");
        } else if (response.statusCode == MSHTTPCodesNo200OK) {
          config = [self deserializeData:data];
          if ([config isValid]) {
            NSURL *configUrl = [MSUtility createFileAtPathComponent:[self identityConfigFilePath]
                                                           withData:data
                                                         atomically:YES
                                                     forceOverwrite:YES];

            // Store eTag only when the configuration file is created successfully.
            if (configUrl) {
              NSString *newETag = [MSHttpIngestion eTagFromResponse:response];
              if (newETag) {
                [MS_USER_DEFAULTS setObject:newETag forKey:kMSIdentityETagKey];
              }
            } else {
              MSLogWarning([MSIdentity logTag], @"Couldn't create Identity config file.");
            }
            @synchronized(self) {
              self.identityConfig = config;

              // Reinitialize client application.
              [self configAuthenticationClient];

              // SignIn if it is delayed.
              /*
               * TODO: SignIn can be called when the app is in background. Make sure the SDK doesn't display browser with signIn screen when
               * the app is in background. Only display in foreground.
               */
              if (self.signInDelayedAndRetryLater) {
                [self signIn];
              }
            }
          } else {
            MSLogError([MSIdentity logTag], @"Downloaded identity configuration is not valid.");
          }
        } else {
          MSLogError([MSIdentity logTag], @"Failed to download identity configuration. Status code received: %ld",
                     (long)response.statusCode);
        }
      }];
}

- (void)configAuthenticationClient {

  // Init MSAL client application.
  NSError *error;
  MSALAuthority *auth = [MSALAuthority authorityWithURL:(NSURL * _Nonnull) self.identityConfig.authorities[0].authorityUrl error:nil];
  self.clientApplication = [[MSALPublicClientApplication alloc] initWithClientId:(NSString * _Nonnull) self.identityConfig.clientId
                                                                       authority:auth
                                                                     redirectUri:self.identityConfig.redirectUri
                                                                           error:&error];
  self.clientApplication.validateAuthority = NO;
  if (error != nil) {
    MSLogError([MSIdentity logTag], @"Failed to initialize client application.");
  }
}

- (void)clearConfigurationCache {
  [MSUtility deleteItemForPathComponent:[self identityConfigFilePath]];
  [MS_USER_DEFAULTS removeObjectForKey:kMSIdentityETagKey];
}

- (MSIdentityConfig *)deserializeData:(NSData *)data {
  NSError *error;
  MSIdentityConfig *config;
  if (data) {
    id dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
      MSLogError([MSIdentity logTag], @"Couldn't parse json data: %@", error.localizedDescription);
    } else {
      config = [[MSIdentityConfig alloc] initWithDictionary:dictionary];
    }
  }
  return config;
}

- (BOOL)clearAuthData {
  if (![[MSAuthTokenContext sharedInstance] clearAuthToken]) {
    MSLogWarning([MSIdentity logTag], @"Couldn't clear authToken: it doesn't exist.");
    return NO;
  }
  BOOL result = YES;
  result &= [self removeAccount];
  result &= [self removeAuthToken];
  [self removeAccountId];
  return result;
}

- (BOOL)removeAccount {
  if (!self.clientApplication) {
    return NO;
  }
  MSALAccount *account = [self retrieveAccountWithAccountId:[self retrieveAccountId]];
  if (account) {
    NSError *error;
    [self.clientApplication removeAccount:account error:&error];
    if (error) {
      MSLogWarning([MSIdentity logTag], @"Failed to remove account: %@", error.localizedDescription);
      return NO;
    }
  }
  return YES;
}

- (void)saveAuthToken:(NSString *)authToken {
  BOOL success = [MSKeychainUtil storeString:authToken forKey:kMSIdentityAuthTokenKey];
  if (success) {
    MSLogDebug([MSIdentity logTag], @"Saved auth token in keychain.");
  } else {
    MSLogWarning([MSIdentity logTag], @"Failed to save auth token in keychain.");
  }
}

- (NSString *)retrieveAuthToken {
  NSString *authToken = [MSKeychainUtil stringForKey:kMSIdentityAuthTokenKey];
  if (authToken) {
    MSLogDebug([MSIdentity logTag], @"Retrieved auth token from keychain.");
  } else {
    MSLogWarning([MSIdentity logTag], @"Failed to retrieve auth token from keychain or none was found.");
  }
  return authToken;
}

- (BOOL)removeAuthToken {
  NSString *authToken = [MSKeychainUtil deleteStringForKey:kMSIdentityAuthTokenKey];
  if (authToken) {
    MSLogDebug([MSIdentity logTag], @"Removed auth token from keychain.");
    return YES;
  } else {
    MSLogWarning([MSIdentity logTag], @"Failed to remove auth token from keychain or none was found.");
    return NO;
  }
}

- (void)acquireTokenSilentlyWithMSALAccount:(MSALAccount *)account {
  __weak typeof(self) weakSelf = self;
  [self.clientApplication
      acquireTokenSilentForScopes:@[ (NSString * _Nonnull) self.identityConfig.identityScope ]
                          account:account
                  completionBlock:^(MSALResult *result, NSError *e) {
                    typeof(self) strongSelf = weakSelf;
                    if (e) {
                      MSLogWarning([MSIdentity logTag],
                                   @"Silent acquisition of token failed with error: %@. Triggering interactive acquisition", e);
                      [strongSelf acquireTokenInteractively];
                    } else {
                      MSALAccountId *accountId = (MSALAccountId * _Nonnull) result.account.homeAccountId;
                      [[MSAuthTokenContext sharedInstance] setAuthToken:(NSString * _Nonnull) result.idToken
                                                          withAccountId:(NSString * _Nonnull) accountId.identifier];
                      [strongSelf saveAuthToken:result.idToken];
                      [strongSelf saveAccountId:(NSString * _Nonnull) result.account.homeAccountId.identifier];
                      [strongSelf completeAcquireTokenRequestForResult:result withError:nil];
                      MSLogInfo([MSIdentity logTag], @"Silent acquisition of token succeeded.");
                    }
                  }];
}

- (void)acquireTokenInteractively {
  __weak typeof(self) weakSelf = self;
  [self.clientApplication acquireTokenForScopes:@[ (NSString * _Nonnull) self.identityConfig.identityScope ]
                                completionBlock:^(MSALResult *result, NSError *e) {
                                  typeof(self) strongSelf = weakSelf;
                                  if (e) {
                                    if (e.code == MSALErrorUserCanceled) {
                                      MSLogWarning([MSIdentity logTag], @"User canceled sign-in.");
                                    } else {
                                      MSLogError([MSIdentity logTag], @"User sign-in failed. Error: %@", e);
                                    }
                                  } else {
                                    MSALAccountId *accountId = (MSALAccountId * _Nonnull) result.account.homeAccountId;
                                    [[MSAuthTokenContext sharedInstance] setAuthToken:(NSString * _Nonnull) result.idToken
                                                                        withAccountId:(NSString * _Nonnull) accountId.identifier];
                                    [strongSelf saveAuthToken:result.idToken];
                                    [strongSelf saveAccountId:(NSString * _Nonnull) result.account.homeAccountId.identifier];
                                    MSLogInfo([MSIdentity logTag], @"User sign-in succeeded.");
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
      userInformation.accountId = (NSString * _Nonnull) result.uniqueId;
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
    MSLogWarning([MSIdentity logTag], @"Could not get MSALAccount for homeAccountId. Error: %@", error);
  }
  return account;
}

- (nullable NSString *)retrieveAccountId {
  return [[MSUserDefaults shared] objectForKey:kMSIdentityMSALAccountHomeAccountKey];
}

- (void)saveAccountId:(NSString *)accountId {
  [[MSUserDefaults shared] setObject:accountId forKey:kMSIdentityMSALAccountHomeAccountKey];
}

- (void)removeAccountId {
  [[MSUserDefaults shared] removeObjectForKey:kMSIdentityMSALAccountHomeAccountKey];
}

@end
