#import "MSAppCenterInternal.h"
#import "MSAppDelegateForwarder.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSConstants+Internal.h"
#import "MSIdentityAppDelegate.h"
#import "MSIdentityConfig.h"
#import "MSIdentityConfigIngestion.h"
#import "MSIdentityPrivate.h"
#import "MSServiceAbstractProtected.h"
#import "MSUtility+File.h"
#import <MSAL/MSALPublicClientApplication.h>

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

// Lock object for synchronization.
static NSObject *lock = @"lock";

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

    // Download identity configuration.
    [self downloadConfigurationWithETag:eTag];
    MSLogInfo([MSIdentity logTag], @"Identity service has been enabled.");
  } else {
    [[MSAppDelegateForwarder sharedInstance] removeDelegate:self.appDelegate];
    self.clientApplication = nil;
    self.idToken = nil;
    [self clearConfigurationCache];
    [self.channelGroup removeDelegate:self];
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

+ (void)login {
  @synchronized(self) {
    if ([[MSIdentity sharedInstance] canBeUsed]) {
      [[MSIdentity sharedInstance] login];
    }
  }
}

- (void)login {
  if (self.clientApplication == nil || self.identityConfig == nil) {
    self.loginDelayed = YES;
    return;
  }
  self.loginDelayed = NO;
  [self.clientApplication acquireTokenForScopes:@[ (NSString * _Nonnull) self.identityConfig.identityScope ]
                                completionBlock:^(MSALResult *result, NSError *e) {
                                  if (e) {
                                    MSLogError([MSIdentity logTag], @"Couldn't initialize authentication client. Error: %@", e);
                                  } else {
                                    self.idToken = result.idToken;
                                  }
                                }];
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
    self.identityConfig = [self deserializeData:configData];
    if (self.identityConfig == nil || ![self.identityConfig isValid]) {
      [self clearConfigurationCache];
      self.identityConfig = nil;
      MSLogError([MSIdentity logTag], @"Identity config file is not valid.");
    } else {
      return YES;
    }
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
            self.identityConfig = config;

            // Reinitialize client application.
            [self configAuthenticationClient];

            // Login if it is delayed.
            /*
             * TODO: Login can be called when the app is in background. Make sure the SDK doesn't display browser with login screen when the
             * app is in background. Only display in foreground.
             */
            if (self.loginDelayed) {
              [self login];
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
  @synchronized(lock) {
    self.clientApplication = [[MSALPublicClientApplication alloc] initWithClientId:(NSString * _Nonnull) self.identityConfig.clientId
                                                                         authority:auth
                                                                       redirectUri:self.identityConfig.redirectUri
                                                                             error:&error];
  }
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

@end
