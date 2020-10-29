// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>

#import "MSACAppCenterInternal.h"
#import "MSACAppDelegateForwarder.h"
#import "MSACChannelUnitConfiguration.h"
#import "MSACChannelUnitProtocol.h"
#import "MSACDependencyConfiguration.h"
#import "MSACDistribute.h"
#import "MSACDistributeAppDelegate.h"
#import "MSACDistributeInternal.h"
#import "MSACDistributePrivate.h"
#import "MSACDistributeUtil.h"
#import "MSACDistributionStartSessionLog.h"
#import "MSACErrorDetails.h"
#import "MSACGuidedAccessUtil.h"
#import "MSACHttpClient.h"
#import "MSACKeychainUtil.h"
#import "MSACSessionContext.h"

/**
 * Service storage key name.
 */
static NSString *const kMSACServiceName = @"Distribute";

/**
 * The group Id for storage.
 */
static NSString *const kMSACGroupId = @"Distribute";

/**
 * Background task to save the browser connection.
 */
static UIBackgroundTaskIdentifier backgroundAuthSessionTask;

#pragma mark - URL constants

/**
 * The API path for update token request.
 */
static NSString *const kMSACUpdateTokenApiPathFormat = @"/apps/%@/private-update-setup";

/**
 * The tester app path for update token request.
 */
static NSString *const kMSACTesterAppUpdateTokenPath = @"ms-actesterapp://update-setup";

#pragma mark - Error constants

static NSString *const kMSACUpdateTokenURLInvalidErrorDescFormat = @"Invalid update token URL:%@";

/**
 * Singleton.
 */
static MSACDistribute *sharedInstance;

static dispatch_once_t onceToken;

@implementation MSACDistribute

@synthesize channelUnitConfiguration = _channelUnitConfiguration;

@synthesize updateTrack = _updateTrack;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    [MSAC_APP_CENTER_USER_DEFAULTS migrateKeys:@{
      @"MSAppCenterDistributeIsEnabled" : @"kMSDistributeIsEnabledKey", // [MSDistribute isEnabled]
      @"MSAppCenterPostponedTimestamp" : @"MSPostponedTimestamp",
      // [MSACDistribute notifyUpdateAction],
      // [MSACDistribute handleUpdate],
      // [MSACDistribute checkLatestRelease]
      @"MSAppCenterSDKHasLaunchedWithDistribute" : @"MSSDKHasLaunchedWithDistribute",
      // [MSACDistribute init],
      // [MSACDistribute checkLatestRelease]
      @"MSAppCenterMandatoryRelease" : @"MSMandatoryRelease",
      // [MSACDistribute checkLatestRelease],
      // [MSACDistribute handleUpdate]
      @"MSAppCenterDistributionGroupId" : @"MSDistributionGroupId",
      // [MSACDistribute startUpdateOnStart],
      // [MSACDistribute processDistributionGroupId],
      // [MSACDistribute changeDistributionGroupIdAfterAppUpdateIfNeeded]
      @"MSAppCenterUpdateSetupFailedPackageHash" : @"MSUpdateSetupFailedPackageHash",
      // [MSACDistribute showUpdateSetupFailedAlert],
      // [MSACDistribute requestInstallInformationWith]
      @"MSAppCenterDownloadedReleaseHash" : @"MSDownloadedReleaseHash",
      // [MSACDistribute storeDownloadedReleaseDetails],
      // [MSACDistribute removeDownloadedReleaseDetailsIfUpdated]
      @"MSAppCenterDownloadedReleaseId" : @"MSDownloadedReleaseId",
      // [MSACDistribute getReportingParametersForUpdatedRelease],
      // [MSACDistribute storeDownloadedReleaseDetails],
      // [MSACDistribute removeDownloadedReleaseDetailsIfUpdated]
      @"MSAppCenterDownloadedDistributionGroupId" : @"MSDownloadedDistributionGroupId",
      // [MSACDistribute changeDistributionGroupIdAfterAppUpdateIfNeeded],
      // [MSACDistribute storeDownloadedReleaseDetails]
      @"MSAppCenterTesterAppUpdateSetupFailed" : @"MSTesterAppUpdateSetupFailed"
      // [MSACDistribute showUpdateSetupFailedAlert],
      // [MSACDistribute openUrl],
      // [MSACDistribute requestInstallInformationWith]
    }
                                    forService:kMSACServiceName];
    [MSACUtility addMigrationClasses:@{
      @"MSReleaseDetails" : MSACReleaseDetails.self,
      @"MSErrorDetails" : MSACErrorDetails.self,
      @"MSDistributionStartSessionLog" : MSACDistributionStartSessionLog.self
    }];

    // Init.
    _apiUrl = kMSACDefaultApiUrl;
    _installUrl = kMSACDefaultInstallUrl;
    _channelUnitConfiguration = [[MSACChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];
    _appDelegate = [MSACDistributeAppDelegate new];

    /*
     * Delete update token if an application has been uninstalled and try to get a new one from server. For iOS version < 10.3, keychain
     * data won't be automatically deleted by uninstall so we should detect it and clean up keychain data when Distribute service gets
     * initialized.
     */
    NSNumber *flag = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACSDKHasLaunchedWithDistribute];
    if (!flag) {
      MSACLogInfo([MSACDistribute logTag], @"Delete update token if exists.");
      [MSACKeychainUtil deleteStringForKey:kMSACUpdateTokenKey];
      [MSAC_APP_CENTER_USER_DEFAULTS setObject:@1 forKey:kMSACSDKHasLaunchedWithDistribute];
    }

    // Set a default value for update track.
    _updateTrack = MSACUpdateTrackPublic;

    /*
     * Proceed update whenever an application is restarted in users perspective.
     * The SDK triggered update flow on UIApplicationWillEnterForeground but listening to UIApplicationDidBecomeActiveNotification
     * notification from version 3.0.0. It isn't reliable to make network calls on foreground so the SDK waits until the app has a
     * focus before making any network calls.
     */
    [MSAC_NOTIFICATION_CENTER addObserver:self
                                 selector:@selector(applicationDidBecomeActive)
                                     name:UIApplicationDidBecomeActiveNotification
                                   object:nil];

    // Init the distribute info tracker.
    _distributeInfoTracker = [[MSACDistributeInfoTracker alloc] init];
  }
  return self;
}

#pragma mark - MSACServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    sharedInstance = [[MSACDistribute alloc] init];
  });
  return sharedInstance;
}

+ (NSString *)serviceName {
  return kMSACServiceName;
}

+ (NSString *)logTag {
  return @"AppCenterDistribute";
}

- (NSString *)groupId {
  return kMSACGroupId;
}

- (MSACInitializationPriority)initializationPriority {

  // Initialize Distribute before Analytics to add distributionGroupId to the first startSession event after app starts.
  return MSACInitializationPriorityHigh;
}

#pragma mark - MSACServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];

  // Enabling
  if (isEnabled) {
    MSACLogInfo([MSACDistribute logTag], @"Distribute service has been enabled.");
    self.releaseDetails = nil;
    [[MSACAppDelegateForwarder sharedInstance] addDelegate:self.appDelegate];

    // Enable the distribute info tracker.
    [self.channelGroup addDelegate:self.distributeInfoTracker];

    // Store distributionGroupId in distributeInfoTracker
    NSString *distributionGroupId = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACDistributionGroupIdKey];
    if (distributionGroupId) {
      MSACLogDebug([MSACDistribute logTag], @"Successfully retrieved distribution group Id setting it in distributeInfoTracker.");
      [self.distributeInfoTracker updateDistributionGroupId:distributionGroupId];
    }

    // Do not start update flow on start if automatic check is disabled.
    if (self.automaticCheckForUpdateDisabled) {
      MSACLogInfo([MSACDistribute logTag], @"Automatic checkForUpdate is disabled.");
      self.updateFlowInProgress = NO;
    } else {
      [self startUpdate];
    }
  } else {
    [self dismissEmbeddedSafari];
    [self.channelGroup removeDelegate:self.distributeInfoTracker];
    [[MSACAppDelegateForwarder sharedInstance] removeDelegate:self.appDelegate];
    [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACUpdateTokenRequestIdKey];
    [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACPostponedTimestampKey];
    [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACMandatoryReleaseKey];
    [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACUpdateSetupFailedPackageHashKey];
    [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACTesterAppUpdateSetupFailedKey];
    MSACLogInfo([MSACDistribute logTag], @"Distribute service has been disabled.");
  }
}

- (void)notifyUpdateAction:(MSACUpdateAction)action {

  @synchronized(self) {
    if (!self.releaseDetails) {
      MSACLogDebug([MSACDistribute logTag], @"The release has already been processed or update flow hasn't started yet.");
      self.updateFlowInProgress = NO;
      return;
    }
    if (!self.updateFlowInProgress) {
      MSACLogInfo([MSACDistribute logTag], @"There is no update flow in progress. Ignore the request.");
      self.releaseDetails = nil;
      return;
    }
    switch (action) {
    case MSACUpdateActionUpdate:

      if ([self isEnabled]) {
        MSACLogDebug([MSACDistribute logTag], @"'Update now' is selected. Start download and install the update.");

        // Store details to report new download after restart if this release is installed.
        [self storeDownloadedReleaseDetails:self.releaseDetails];
#if TARGET_OS_SIMULATOR

        /*
         * iOS simulator doesn't support "itms-services" scheme, simulator will consider the scheme as an invalid address. Skip download
         * process if the application is running on simulator.
         */
        MSACLogWarning([MSACDistribute logTag], @"Couldn't download a new release on simulator.");
#else
        [self startDownload:self.releaseDetails];
#endif
      } else {
        MSACLogDebug([MSACDistribute logTag], @"'Update now' is selected but Distribute was disabled.");
        [self showDistributeDisabledAlert];
      }
      break;
    case MSACUpdateActionPostpone:
      MSACLogDebug([MSACDistribute logTag], @"The SDK will ask for the update again tomorrow.");
      [MSAC_APP_CENTER_USER_DEFAULTS setObject:@((long long)[MSACUtility nowInMilliseconds]) forKey:kMSACPostponedTimestampKey];
      break;
    }

    // The release details have been processed. Clean up the variable.
    self.updateFlowInProgress = NO;
    self.releaseDetails = nil;
  }
}

- (void)startWithChannelGroup:(id<MSACChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  if (appSecret) {
    id<MSACHttpClientProtocol> httpClient = [MSACDependencyConfiguration httpClient];
    if (!httpClient) {
      httpClient = [MSACHttpClient new];
    }

    // Start Ingestion.
    self.ingestion = [[MSACDistributeIngestion alloc] initWithHttpClient:httpClient
                                                                 baseUrl:self.apiUrl
                                                               appSecret:(NSString * _Nonnull) appSecret];

    // Channel group should be started after Ingestion is ready.
    [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
    MSACLogVerbose([MSACDistribute logTag], @"Started Distribute service.");
  } else {
    MSACLogError([MSACDistribute logTag], @"Failed to start Distribute because app secret isn't specified.");
  }
}

#pragma mark - Public

+ (id<MSACDistributeDelegate>)delegate {
  return [MSACDistribute sharedInstance].delegate;
}

+ (NSString *)apiUrl {
  return [MSACDistribute sharedInstance].apiUrl;
}

+ (NSString *)installUrl {
  return [MSACDistribute sharedInstance].installUrl;
}

+ (void)setApiUrl:(NSString *)apiUrl {
  [[MSACDistribute sharedInstance] setApiUrl:apiUrl];
}

+ (void)setInstallUrl:(NSString *)installUrl {
  [[MSACDistribute sharedInstance] setInstallUrl:installUrl];
}

+ (BOOL)openURL:(NSURL *)url {
  return [[MSACDistribute sharedInstance] openURL:url];
}

+ (void)notifyUpdateAction:(MSACUpdateAction)action {
  [[MSACDistribute sharedInstance] notifyUpdateAction:action];
}

+ (void)setDelegate:(id<MSACDistributeDelegate>)delegate {
  [[MSACDistribute sharedInstance] setDelegate:delegate];
}

+ (void)setUpdateTrack:(MSACUpdateTrack)updateTrack {
  [MSACDistribute sharedInstance].updateTrack = updateTrack;
}

+ (MSACUpdateTrack)updateTrack {
  return [MSACDistribute sharedInstance].updateTrack;
}

+ (void)disableAutomaticCheckForUpdate {
  [[MSACDistribute sharedInstance] disableAutomaticCheckForUpdate];
}

+ (void)checkForUpdate {
  [[MSACDistribute sharedInstance] checkForUpdate];
}

#pragma mark - Private

- (void)sendFirstSessionUpdateLog {
  MSACLogDebug([MSACDistribute logTag], @"Updating the session count.");

  // log the first session after an install.
  MSACDistributionStartSessionLog *log = [[MSACDistributionStartSessionLog alloc] init];

  // Send log to log manager.
  [self.channelUnit enqueueItem:log flags:MSACFlagsDefault];
}

- (void)startUpdate {
  NSString *releaseHash = MSACPackageHash();
  if (releaseHash) {
    [self changeDistributionGroupIdAfterAppUpdateIfNeeded:releaseHash];
    OSStatus statusCode;
    NSString *updateToken = [MSACKeychainUtil stringForKey:kMSACUpdateTokenKey statusCode:&statusCode];
    if (statusCode == errSecInteractionNotAllowed) {
      MSACLogError([MSACDistribute logTag], @"Failed to get update token from keychain. This might occur when the device is locked.");
      return;
    }
    NSString *distributionGroupId = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACDistributionGroupIdKey];
    @synchronized(self) {
      if (self.updateFlowInProgress) {
        MSACLogDebug([MSACDistribute logTag], @"Previous update flow is in progress. Ignore the request.");
        return;
      }
      self.updateFlowInProgress = YES;
    }
    if (updateToken || self.updateTrack == MSACUpdateTrackPublic) {
      [self checkLatestRelease:updateToken distributionGroupId:distributionGroupId releaseHash:releaseHash];
    } else {
      [self requestInstallInformationWith:releaseHash];
    }
  } else {
    MSACLogError([MSACDistribute logTag], @"Failed to get a release hash.");
  }
}

- (void)requestInstallInformationWith:(NSString *)releaseHash {

  // Check if it's okay to check for updates.
  if ([self checkForUpdatesAllowed]) {

    // Check if the device has internet connection to get update token.
    if ([MSAC_Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
      MSACLogWarning([MSACDistribute logTag],
                     @"The device lost its internet connection. The SDK will retry to get an update token in the next launch.");
      return;
    }

    /*
     * If failed to enable in-app updates on the same app build before, don't try again. Only if the app build is different (different
     * package hash), try enabling in-app updates again.
     */
    NSString *updateSetupFailedPackageHash = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACUpdateSetupFailedPackageHashKey];
    if (updateSetupFailedPackageHash) {
      if ([updateSetupFailedPackageHash isEqualToString:releaseHash]) {
        MSACLogDebug([MSACDistribute logTag], @"Skipping in-app updates setup, because it already failed on this release before.");
        return;
      } else {
        MSACLogDebug([MSACDistribute logTag], @"Re-attempting in-app updates setup and cleaning up failure info from storage.");
        [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACUpdateSetupFailedPackageHashKey];
        [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACTesterAppUpdateSetupFailedKey];
      }
    }

    // Create the request ID string and persist it.
    NSString *requestId = MSAC_UUID_STRING;
    [MSAC_APP_CENTER_USER_DEFAULTS setObject:requestId forKey:kMSACUpdateTokenRequestIdKey];
    MSACLogInfo([MSACDistribute logTag], @"Request information of initial installation.");

    // Don't run on the UI thread, or else the app may be slow to startup.
    NSURL *testerAppUrl = [self buildTokenRequestURLWithAppSecret:self.appSecret releaseHash:releaseHash isTesterApp:true];
    NSURL *installUrl = [self buildTokenRequestURLWithAppSecret:self.appSecret releaseHash:releaseHash isTesterApp:false];
    dispatch_async(dispatch_get_main_queue(), ^{
      BOOL shouldUseTesterAppForUpdateSetup = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACTesterAppUpdateSetupFailedKey] == NULL;
      BOOL testerAppOpened = NO;
      if (shouldUseTesterAppForUpdateSetup) {
        MSACLogInfo([MSACDistribute logTag], @"Attempting to use tester app for update setup.");

        // Attempt to open the native iOS tester app to enable in-app updates.
        if (testerAppUrl) {
          testerAppOpened = [self openUrlUsingSharedApp:testerAppUrl];
          if (testerAppOpened) {
            MSACLogInfo([MSACDistribute logTag], @"Tester app was successfully opened to enable in-app updates.");
          } else {
            MSACLogInfo([MSACDistribute logTag], @"Tester app could not be opened to enable in-app updates (not installed?)");
          }
        }
      }

      // If the native app could not be opened (not installed), fall back to the browser update setup.
      if ((!shouldUseTesterAppForUpdateSetup || !testerAppOpened) && installUrl) {
        [self openUrlInAuthenticationSessionOrSafari:installUrl];
      }
    });
  } else {

    // Log a message to notify the user why the SDK didn't check for updates.
    MSACLogDebug([MSACDistribute logTag],
                 @"Distribute won't try to obtain an update token because of one of the following reasons: "
                 @"1. A debugger is attached. "
                 @"2. You are running the debug configuration. "
                 @"3. The app is running in a non-adhoc environment. "
                 @"4. The device is in guided access mode which prevents opening update URLs. "
                 @"Detach the debugger and restart the app and/or run the app with the release configuration and/or "
                 @"deactivate guided access mode to enable the feature.");
  }
}

- (void)checkLatestRelease:(NSString *)updateToken distributionGroupId:(NSString *)distributionGroupId releaseHash:(NSString *)releaseHash {

  // Check if it's okay to check for updates.
  if ([self checkForUpdatesAllowed]) {

    // Use persisted mandatory update while network is down.
    if ([MSAC_Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
      MSACReleaseDetails *details =
          [[MSACReleaseDetails alloc] initWithDictionary:[MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACMandatoryReleaseKey]];
      if (details && ![self handleUpdate:details]) {

        // This release is no more a candidate for update, deleting it.
        [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACMandatoryReleaseKey];
      }
    }

    // Handle update.
    __weak typeof(self) weakSelf = self;
    MSACSendAsyncCompletionHandler completionHandler =
        ^(__unused NSString *callId, NSHTTPURLResponse *response, NSData *data, __unused NSError *error) {
          typeof(self) strongSelf = weakSelf;
          if (!strongSelf) {
            return;
          }

          // Ignore the response if the service is disabled.
          if (![strongSelf isEnabled]) {
            return;
          }

          // Error instance for JSON parsing.
          NSError *jsonError = nil;

          // Success.
          if (response.statusCode == MSACHTTPCodesNo200OK) {
            MSACReleaseDetails *details = nil;
            if (data) {
              id dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
              if (jsonError) {
                MSACLogError([MSACDistribute logTag], @"Couldn't parse json data: %@", jsonError.localizedDescription);
              }
              details = [[MSACReleaseDetails alloc] initWithDictionary:dictionary];
            }
            if (!details) {
              MSACLogError([MSACDistribute logTag], @"Couldn't parse response payload.");
              strongSelf.updateFlowInProgress = NO;
            } else {

              // Check if downloaded release was installed and remove stored release details.
              [self removeDownloadedReleaseDetailsIfUpdated:releaseHash];

              // If there is not already a saved public distribution group, process it now.
              NSString *existingDistributionGroupId = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACDistributionGroupIdKey];
              if (!existingDistributionGroupId && details.distributionGroupId) {
                [self processDistributionGroupId:details.distributionGroupId];
              }

              /*
               * Handle this update.
               *
               * NOTE: There is one glitch when this release is the same than the currently displayed mandatory release. In this case
               * the current UI will be dismissed then redisplayed with the same UI content. This is an edge case since it's only
               * happening if there was no network at app start then network came back along with the same mandatory release from the
               * server. In addition to that and even though the releases are the same, the URL links generated by the server will be
               * different.
               * Thus, there is the overhead of updating the currently displayed download action with the new URL. In the end fixing
               * this edge case adds too much complexity for no worthy advantages, keeping it as it is for now.
               */
              if (![strongSelf handleUpdate:details]) {
                strongSelf.updateFlowInProgress = NO;
              }
            }
          }

          // Failure.
          else {
            MSACLogError([MSACDistribute logTag], @"Failed to get an update response, status code: %tu", response.statusCode);

            // Check the status code to clean up Distribute data for an unrecoverable error.
            if (![MSACHttpUtil isRecoverableError:response.statusCode]) {

              // Deserialize payload to check if it contains error details.
              MSACErrorDetails *details = nil;
              if (data) {
                id dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                if (dictionary) {
                  details = [[MSACErrorDetails alloc] initWithDictionary:dictionary];
                }
              }

              // If the response payload is MSACErrorDetails, consider it as a recoverable error.
              if (!details || ![kMSACErrorCodeNoReleasesForUser isEqualToString:details.code]) {
                [MSACKeychainUtil deleteStringForKey:kMSACUpdateTokenKey];
                [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACSDKHasLaunchedWithDistribute];
                [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACUpdateTokenRequestIdKey];
                [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACPostponedTimestampKey];
                [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACDistributionGroupIdKey];
                [self.distributeInfoTracker removeDistributionGroupId];
              }
            }

            // Reset the flag after handling the failure.
            strongSelf.updateFlowInProgress = NO;
          }
        };

    // Build query strings.
    NSMutableDictionary *queryStrings = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *reportingParametersForUpdatedRelease =
        [self getReportingParametersForUpdatedRelease:(self.updateTrack == MSACUpdateTrackPublic)
                          currentInstalledReleaseHash:releaseHash
                                  distributionGroupId:distributionGroupId];
    if (reportingParametersForUpdatedRelease != nil) {
      [queryStrings addEntriesFromDictionary:reportingParametersForUpdatedRelease];
    }
    queryStrings[kMSACURLQueryReleaseHashKey] = releaseHash;

    if (self.updateTrack == MSACUpdateTrackPrivate) {
      if (updateToken) {
        [self.ingestion checkForPrivateUpdateWithUpdateToken:updateToken queryStrings:queryStrings completionHandler:completionHandler];
      } else {
        MSACLogError([MSACDistribute logTag], @"Update token is missing. Please authenticate Distribute first.");
      }
    } else {
      [self.ingestion checkForPublicUpdateWithQueryStrings:queryStrings completionHandler:completionHandler];
    }
  } else {

    // Log a message to notify the user why the SDK didn't check for updates.
    MSACLogDebug([MSACDistribute logTag], @"Distribute won't check if a new release is available because of one of the following reasons: "
                                          @"1. A debugger is attached. "
                                          @"2. You are running the debug configuration. "
                                          @"3. The app is running in a non-adhoc environment. "
                                          @"Detach the debugger and restart the app and/or run the app with the release configuration "
                                          @"to enable the feature.");
    self.updateFlowInProgress = NO;
  }
}

#pragma mark - Private

- (BOOL)checkURLSchemeRegistered:(NSString *)urlScheme {
  NSArray *schemes;
  NSArray *types = [MSAC_APP_MAIN_BUNDLE objectForInfoDictionaryKey:kMSACCFBundleURLTypes];
  for (NSDictionary *urlType in types) {
    schemes = urlType[kMSACCFBundleURLSchemes];
    for (NSString *scheme in schemes) {
      if ([scheme isEqualToString:urlScheme]) {
        return YES;
      }
    }
  }
  return NO;
}

- (nullable NSURL *)buildTokenRequestURLWithAppSecret:(NSString *)appSecret
                                          releaseHash:(NSString *)releaseHash
                                          isTesterApp:(BOOL)isTesterApp {

  // Check custom scheme is registered.
  NSString *scheme = [NSString stringWithFormat:kMSACDefaultCustomSchemeFormat, appSecret];
  if (![self checkURLSchemeRegistered:scheme]) {
    MSACLogError([MSACDistribute logTag], @"Custom URL scheme for Distribute not found.");
    return nil;
  }

  // Build URL string.
  NSString *urlString;
  if (isTesterApp) {
    urlString = kMSACTesterAppUpdateTokenPath;
  } else {
    NSString *urlPath = [NSString stringWithFormat:kMSACUpdateTokenApiPathFormat, appSecret];
    urlString = [self.installUrl stringByAppendingString:urlPath];
  }
  NSURLComponents *components = [NSURLComponents componentsWithString:urlString];

  // Check URL validity so far.
  if (!components) {
    NSString *obfuscatedUrl = [urlString stringByReplacingOccurrencesOfString:appSecret withString:[MSACHttpUtil hideSecret:urlString]];
    MSACLogError([MSACDistribute logTag], kMSACUpdateTokenURLInvalidErrorDescFormat, obfuscatedUrl);
    return nil;
  }

  // Get the stored request ID, or create one if it doesn't exist yet.
  NSString *requestId = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACUpdateTokenRequestIdKey];
  if (!requestId) {
    requestId = MSAC_UUID_STRING;
    [MSAC_APP_CENTER_USER_DEFAULTS setObject:requestId forKey:kMSACUpdateTokenRequestIdKey];
  }

  // Set URL query parameters.
  NSMutableArray *items = [NSMutableArray array];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSACURLQueryReleaseHashKey value:releaseHash]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSACURLQueryRedirectIdKey value:scheme]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSACURLQueryRequestIdKey value:requestId]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSACURLQueryPlatformKey value:kMSACURLQueryPlatformValue]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSACURLQueryEnableUpdateSetupFailureRedirectKey value:@"true"]];
  components.queryItems = items;

  // Check URL validity.
  if (!components.URL) {
    MSACLogError([MSACDistribute logTag], kMSACUpdateTokenURLInvalidErrorDescFormat, components);
    return nil;
  }
  return components.URL;
}

- (BOOL)openUrlUsingSharedApp:(NSURL *)url {
  UIApplication *sharedApp = [MSACUtility sharedApp];
  return (BOOL)[sharedApp performSelector:@selector(openURL:) withObject:url];
}

- (void)openUrlInAuthenticationSessionOrSafari:(NSURL *)url {

  /*
   * Only iOS 9.x and 10.x will download the update after users click the "Install" button. We need to force-exit the application for other
   * versions or for any versions when the update is mandatory.
   */

  // TODO SFAuthenticationSession is deprecated, for iOS 12 use ASWebAuthenticationSession
  if (@available(iOS 11.0, *)) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self openURLInAuthenticationSessionWith:url];
    });
  } else {
    Class clazz = [SFSafariViewController class];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self openURLInSafariViewControllerWith:url fromClass:clazz];
    });
  }
}

- (void)openURLInAuthenticationSessionWith:(NSURL *)url API_AVAILABLE(ios(11)) {
  NSString *obfuscatedUrl = [url.absoluteString stringByReplacingOccurrencesOfString:self.appSecret
                                                                          withString:[MSACHttpUtil hideSecret:url.absoluteString]];
  MSACLogDebug([MSACDistribute logTag], @"Using SFAuthenticationSession to open URL: %@", obfuscatedUrl);
  NSString *callbackUrlScheme = [NSString stringWithFormat:kMSACDefaultCustomSchemeFormat, self.appSecret];

  // The completion block that we need to invoke.
  __weak typeof(self) weakSelf = self;
  typedef void (^MSACCompletionBlockForAuthSession)(NSURL *callbackUrl, NSError *error);
  MSACCompletionBlockForAuthSession authCompletionBlock = ^(NSURL *callbackUrl, NSError *error) {
    typeof(self) strongSelf = weakSelf;
    if (!strongSelf) {
      [[MSACUtility sharedApp] endBackgroundTask:backgroundAuthSessionTask];
      return;
    }
    if (error) {
      MSACLogDebug([MSACDistribute logTag], @"Called %@ with error: %@", callbackUrl, error.localizedDescription);
    }
    if (error.code == SFAuthenticationErrorCanceledLogin) {
      MSACLogError([MSACDistribute logTag], @"Authentication session was cancelled by user or failed.");
    }
    if (callbackUrl) {
      [strongSelf openURL:callbackUrl];
    } else {
      self.updateFlowInProgress = NO;
    }
    [[MSACUtility sharedApp] endBackgroundTask:backgroundAuthSessionTask];
  };
  SFAuthenticationSession *session = [[SFAuthenticationSession alloc] initWithURL:url
                                                                callbackURLScheme:callbackUrlScheme
                                                                completionHandler:authCompletionBlock];

  // Calling 'start' on an existing session crashes the application - cancel session.
  [self.authenticationSession cancel];

  // Retain the session.
  self.authenticationSession = session;

  /*
   * Request additional background execution time for authorization. If we authorize using third-party services (MSAC Authenticator)
   * then switching to another application will kill the current session. This line fixes this problem.
   */
  backgroundAuthSessionTask = [[MSACUtility sharedApp] beginBackgroundTaskWithName:@"Safari authentication"
                                                                 expirationHandler:^{
                                                                   [[MSACUtility sharedApp] endBackgroundTask:backgroundAuthSessionTask];
                                                                 }];
  if ([session start]) {
    MSACLogDebug([MSACDistribute logTag], @"Authentication session started, showing confirmation dialog.");
  } else {
    MSACLogError([MSACDistribute logTag], @"Failed to start authentication session.");
    self.updateFlowInProgress = NO;
  }
}

- (void)openURLInSafariViewControllerWith:(NSURL *)url fromClass:(Class)clazz {
  MSACLogDebug([MSACDistribute logTag], @"Using SFSafariViewController to open URL: %@", url);
#pragma clang diagnostic push

// Ignore "Unknown warning group '-Wobjc-messaging-id'" for old XCode
#pragma clang diagnostic ignored "-Wunknown-pragmas"
#pragma clang diagnostic ignored "-Wunknown-warning-option"

// Ignore "Messaging unqualified id" for XCode 10
#pragma clang diagnostic ignored "-Wobjc-messaging-id"

  // Init safari controller with the install URL.
  id safari = [[clazz alloc] initWithURL:url];
#pragma clang diagnostic pop

  // Create an empty window + viewController to host the Safari UI.
  self.safariHostingViewController = [[UIViewController alloc] init];
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  window.rootViewController = self.safariHostingViewController;

  // Place it at the highest level within the stack.
  window.windowLevel = +CGFLOAT_MAX;

  // Run it.
  [window makeKeyAndVisible];
  [self.safariHostingViewController presentViewController:safari animated:YES completion:nil];
}

- (void)dismissEmbeddedSafari {
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    typeof(self) strongSelf = weakSelf;
    if (strongSelf && strongSelf.safariHostingViewController && !strongSelf.safariHostingViewController.isBeingDismissed) {
      [strongSelf.safariHostingViewController dismissViewControllerAnimated:YES completion:nil];
    }
  });
}

- (BOOL)handleUpdate:(MSACReleaseDetails *)details {

  // Step 1. Validate release details.
  if (!details || ![details isValid]) {
    MSACLogError([MSACDistribute logTag], @"Received invalid release details.");
    return NO;
  }

  // Step 2. Check status of the release. TODO: This will be deprecated soon.
  if (![details.status isEqualToString:@"available"]) {
    MSACLogError([MSACDistribute logTag], @"The new release is not available, skip update.");
    return NO;
  }

  // Step 3. Check if the update is postponed by a user.
  NSNumber *postponedTimestamp = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACPostponedTimestampKey];
  if (postponedTimestamp) {
    long long duration = (long long)[MSACUtility nowInMilliseconds] - [postponedTimestamp longLongValue];
    if (duration >= 0 && duration < kMSACDayInMillisecond) {
      if (details.mandatoryUpdate) {
        MSACLogDebug([MSACDistribute logTag],
                     @"The update was postponed within a day ago but the update is a mandatory update. The SDK will "
                     @"proceed update for the release.");
      } else {
        MSACLogDebug([MSACDistribute logTag], @"The update was postponed within a day ago, skip update.");
        return NO;
      }
    }
    [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACPostponedTimestampKey];
  }

  // Step 4. Check min OS version.
  if ([MSAC_DEVICE.systemVersion compare:details.minOs options:NSNumericSearch] == NSOrderedAscending) {
    MSACLogDebug([MSACDistribute logTag], @"The new release doesn't support this iOS version: %@, skip update.", MSAC_DEVICE.systemVersion);
    return NO;
  }

  // Step 5. Check version/hash to identify a newer version.
  if (![self isNewerVersion:details]) {
    MSACLogDebug([MSACDistribute logTag], @"The application is already up-to-date.");
    return NO;
  }

  // Step 6. Persist this mandatory update to cover offline scenario.
  if (details.mandatoryUpdate) {

    // Persist this mandatory update now.
    [MSAC_APP_CENTER_USER_DEFAULTS setObject:[details serializeToDictionary] forKey:kMSACMandatoryReleaseKey];
  } else {

    // Clean up mandatory release cache.
    [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACMandatoryReleaseKey];
  }

  // Step 7. Open a dialog and ask a user to choose options for the update.
  if (!self.releaseDetails || ![self.releaseDetails isEqual:details]) {
    self.releaseDetails = details;
    id<MSACDistributeDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(distribute:releaseAvailableWithDetails:)]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        BOOL customized = [delegate distribute:self releaseAvailableWithDetails:details];
        MSACLogDebug([MSACDistribute logTag], @"releaseAvailableWithDetails delegate returned %@.", customized ? @"YES" : @"NO");
        if (!customized) {
          [self showConfirmationAlert:details];
        }
      });
    } else {
      [self showConfirmationAlert:details];
    }
  }
  return YES;
}

- (BOOL)checkForUpdatesAllowed {

  // Check if we are not in AppStore or TestFlight environments.
  BOOL compatibleEnvironment = [MSACUtility currentAppEnvironment] == MSACEnvironmentOther;

  // Check if we are currently in guided access mode. Guided access mode prevents opening update URLs.
  BOOL guidedAccessModeEnabled = [MSACGuidedAccessUtil isGuidedAccessEnabled];

  // Check if a debugger is attached.
  BOOL debuggerAttached = [MSACAppCenter isDebuggerAttached];
  return compatibleEnvironment && !debuggerAttached && !guidedAccessModeEnabled;
}

- (BOOL)isNewerVersion:(MSACReleaseDetails *)details {
  return MSACCompareCurrentReleaseWithRelease(details) == NSOrderedAscending;
}

- (void)storeDownloadedReleaseDetails:(nullable MSACReleaseDetails *)details {
  if (details == nil) {
    MSACLogDebug([MSACDistribute logTag], @"Downloaded release details are missing or broken, won't store.");
    return;
  }
  NSString *groupId = details.distributionGroupId;
  NSNumber *releaseId = details.id;

  /*
   * IPA can contain several hashes, each for different architecture and we can't predict which will be installed, so save all hashes as
   * comma separated string.
   */
  NSString *releaseHashes = [details.packageHashes count] > 0 ? [details.packageHashes componentsJoinedByString:@","] : nil;
  [MSAC_APP_CENTER_USER_DEFAULTS setObject:groupId forKey:kMSACDownloadedDistributionGroupIdKey];
  [MSAC_APP_CENTER_USER_DEFAULTS setObject:releaseId forKey:kMSACDownloadedReleaseIdKey];
  [MSAC_APP_CENTER_USER_DEFAULTS setObject:releaseHashes forKey:kMSACDownloadedReleaseHashKey];
  MSACLogDebug([MSACDistribute logTag], @"Stored downloaded release hash(es) (%@) and id (%@) for later reporting.", releaseHashes,
               releaseId);
}

- (void)removeDownloadedReleaseDetailsIfUpdated:(NSString *)currentInstalledReleaseHash {
  NSString *lastDownloadedReleaseHashes = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACDownloadedReleaseHashKey];
  if (lastDownloadedReleaseHashes == nil) {
    return;
  }
  if ([lastDownloadedReleaseHashes rangeOfString:currentInstalledReleaseHash].location == NSNotFound) {
    MSACLogDebug([MSACDistribute logTag],
                 @"Stored release hash(es) (%@) doesn't match current installation hash (%@), "
                 @"probably downloaded but not installed yet, keep in store.",
                 lastDownloadedReleaseHashes, currentInstalledReleaseHash);
    return;
  }

  // Successfully reported, remove downloaded release details.
  MSACLogDebug([MSACDistribute logTag], @"Successfully reported app update for downloaded release hash (%@), removing from store.",
               currentInstalledReleaseHash);
  [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACDownloadedReleaseIdKey];
  [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACDownloadedReleaseHashKey];
}

- (nullable NSMutableDictionary *)getReportingParametersForUpdatedRelease:(BOOL)isPublic
                                              currentInstalledReleaseHash:(NSString *)currentInstalledReleaseHash
                                                      distributionGroupId:(NSString *)distributionGroupId {

  // Check if we need to report release installation.
  NSString *lastDownloadedReleaseHashes = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACDownloadedReleaseHashKey];
  if (lastDownloadedReleaseHashes == nil) {
    MSACLogDebug([MSACDistribute logTag], @"Current release was already reported, skip reporting.");
    return nil;
  }

  // Skip if downloaded release not installed yet.
  if ([lastDownloadedReleaseHashes rangeOfString:currentInstalledReleaseHash].location == NSNotFound) {
    MSACLogDebug([MSACDistribute logTag], @"New release was downloaded but not installed yet, skip reporting.");
    return nil;
  }

  // Return reporting parameters.
  MSACLogDebug([MSACDistribute logTag], @"Current release was updated but not reported yet, reporting.");
  NSMutableDictionary *reportingParameters = [[NSMutableDictionary alloc] init];
  reportingParameters[kMSACURLQueryDistributionGroupIdKey] = distributionGroupId;
  if (isPublic) {
    reportingParameters[kMSACURLQueryInstallIdKey] = [[MSACAppCenter installId] UUIDString];
  }
  NSString *lastDownloadedReleaseId = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACDownloadedReleaseIdKey];
  reportingParameters[kMSACURLQueryDownloadedReleaseIdKey] = lastDownloadedReleaseId;
  return reportingParameters;
}

- (void)changeDistributionGroupIdAfterAppUpdateIfNeeded:(NSString *)currentInstalledReleaseHash {
  NSString *updatedReleaseDistributionGroupId = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACDownloadedDistributionGroupIdKey];
  if (updatedReleaseDistributionGroupId == nil) {
    return;
  }

  // Skip if the current release was not updated.
  NSString *updatedReleaseHashes = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACDownloadedReleaseHashKey];
  if ((updatedReleaseHashes == nil) || ([updatedReleaseHashes rangeOfString:currentInstalledReleaseHash].location == NSNotFound)) {
    return;
  }

  // Skip if the group ID of an updated release is the same as the stored one.
  NSString *storedDistributionGroupId = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACDistributionGroupIdKey];
  if ((storedDistributionGroupId == nil) || ([updatedReleaseDistributionGroupId isEqualToString:storedDistributionGroupId] == NO)) {

    // Set group ID from downloaded release details if an updated release was downloaded from another distribution group.
    MSACLogDebug([MSACDistribute logTag], @"Stored group ID doesn't match the group ID of the updated release, updating group id: %@",
                 updatedReleaseDistributionGroupId);
    [MSAC_APP_CENTER_USER_DEFAULTS setObject:updatedReleaseDistributionGroupId forKey:kMSACDistributionGroupIdKey];
  }

  // Remove saved downloaded group ID.
  [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACDownloadedDistributionGroupIdKey];
}

- (void)showConfirmationAlert:(MSACReleaseDetails *)details {

  // Displaying alert dialog. Running on main thread.
  dispatch_async(dispatch_get_main_queue(), ^{
    // Init the alert controller.
    NSString *messageFormat = details.mandatoryUpdate
                                  ? MSACDistributeLocalizedString(@"MSDistributeAppUpdateAvailableMandatoryUpdateMessage")
                                  : MSACDistributeLocalizedString(@"MSDistributeAppUpdateAvailableOptionalUpdateMessage");
    NSString *appName = [MSAC_APP_MAIN_BUNDLE objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!appName) {
      appName = [MSAC_APP_MAIN_BUNDLE objectForInfoDictionaryKey:@"CFBundleName"];
    }

// FIXME: Format string should be a string literal but its format is in string resource so it won't be. Disable the warning temporarily.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
    NSString *message = [NSString stringWithFormat:messageFormat, appName, details.shortVersion, details.version];
#pragma clang diagnostic pop
    MSACAlertController *alertController =
        [MSACAlertController alertControllerWithTitle:MSACDistributeLocalizedString(@"MSDistributeAppUpdateAvailable") message:message];

    if (!details.mandatoryUpdate) {

      // Add a "Ask me in a day"-Button.
      [alertController addDefaultActionWithTitle:MSACDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                         handler:^(__attribute__((unused)) UIAlertAction *action) {
                                           [self notifyUpdateAction:MSACUpdateActionPostpone];
                                         }];
    }

    if ([details.releaseNotes length] > 0 && details.releaseNotesUrl) {

      // Add a "View release notes"-Button.
      [alertController addDefaultActionWithTitle:MSACDistributeLocalizedString(@"MSDistributeViewReleaseNotes")
                                         handler:^(__attribute__((unused)) UIAlertAction *action) {
                                           MSACLogDebug([MSACDistribute logTag],
                                                        @"'View release notes' is selected. Open a browser and show release notes.");
                                           [MSACUtility sharedAppOpenUrl:details.releaseNotesUrl options:@{} completionHandler:nil];

                                           /*
                                            * Clear release details so that the SDK can get the latest release again after coming back from
                                            * release notes.
                                            */
                                           self.releaseDetails = nil;
                                           self.updateFlowInProgress = NO;
                                         }];
    }

    // Add a "Update now"-Button.
    [alertController addPreferredActionWithTitle:MSACDistributeLocalizedString(@"MSDistributeUpdateNow")
                                         handler:^(__attribute__((unused)) UIAlertAction *action) {
                                           [self notifyUpdateAction:MSACUpdateActionUpdate];
                                         }];

    /*
     * Show the alert controller. It will replace any previous release alert. This happens when the network was down so the persisted
     * release was displayed but the network came back with a fresh release.
     */
    MSACLogDebug([MSACDistribute logTag], @"Show update dialog.");
    [alertController replaceAlert:self.updateAlertController];
    self.updateAlertController = alertController;
  });
}

- (void)showDistributeDisabledAlert {
  dispatch_async(dispatch_get_main_queue(), ^{
    MSACAlertController *alertController =
        [MSACAlertController alertControllerWithTitle:MSACDistributeLocalizedString(@"MSDistributeInAppUpdatesAreDisabled") message:nil];
    [alertController addCancelActionWithTitle:MSACDistributeLocalizedString(@"MSDistributeClose") handler:nil];
    [alertController show];
  });
}

- (void)showUpdateSetupFailedAlert:(NSString *)errorMessage {

  // Not using the error message coming from backend due to non-localized text.
  (void)errorMessage;
  dispatch_async(dispatch_get_main_queue(), ^{
    MSACAlertController *alertController =
        [MSACAlertController alertControllerWithTitle:MSACDistributeLocalizedString(@"MSDistributeInAppUpdatesAreDisabled")
                                              message:MSACDistributeLocalizedString(@"MSDistributeInstallFailedMessage")];

    // Add "Ignore" button to the dialog
    [alertController addDefaultActionWithTitle:MSACDistributeLocalizedString(@"MSDistributeIgnore")
                                       handler:^(__attribute__((unused)) UIAlertAction *action) {
                                         [MSAC_APP_CENTER_USER_DEFAULTS setObject:MSACPackageHash()
                                                                           forKey:kMSACUpdateSetupFailedPackageHashKey];
                                       }];

    // Add "Reinstall" button to the dialog
    [alertController
        addPreferredActionWithTitle:MSACDistributeLocalizedString(@"MSDistributeReinstall")
                            handler:^(__attribute__((unused)) UIAlertAction *action) {
                              NSURL *installUrl = [NSURL URLWithString:[self installUrl]];

                              /*
                               * Add a flag to the install url to indicate that the update setup failed, to show a help page
                               */
                              NSURLComponents *components = [[NSURLComponents alloc] initWithURL:installUrl resolvingAgainstBaseURL:NO];
                              NSURLQueryItem *newQueryItem = [[NSURLQueryItem alloc] initWithName:kMSACURLQueryUpdateSetupFailedKey
                                                                                            value:@"true"];
                              NSMutableArray *newQueryItems = [NSMutableArray arrayWithCapacity:[components.queryItems count] + 1];
                              for (NSURLQueryItem *qi in components.queryItems) {
                                if (![qi.name isEqual:newQueryItem.name]) {
                                  [newQueryItems addObject:qi];
                                }
                              }
                              [newQueryItems addObject:newQueryItem];
                              [components setQueryItems:newQueryItems];

                              // Open the install URL with query parameter update_setup_failed=true
                              installUrl = [components URL];
                              [self openUrlInAuthenticationSessionOrSafari:installUrl];

                              // Clear the update setup failure info from storage, to re-attempt setup on reinstall
                              [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACTesterAppUpdateSetupFailedKey];
                              [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACUpdateSetupFailedPackageHashKey];
                            }];

    [alertController show];
  });
}

- (void)startDownload:(nullable MSACReleaseDetails *)details {
  [MSACUtility
       sharedAppOpenUrl:details.installUrl
                options:@{}
      completionHandler:^(MSACOpenURLState state) {
        switch (state) {
        case MSACOpenURLStateSucceed:
          MSACLogDebug([MSACDistribute logTag], @"Start updating the application.");
          break;
        case MSACOpenURLStateFailed:
          MSACLogError([MSACDistribute logTag], @"System couldn't open the URL. Aborting update.");
          return;
        case MSACOpenURLStateUnknown:

          /*
           * FIXME: We've observed a behavior in iOS 10+ that openURL and openURL:options:completionHandler don't say the operation is
           * succeeded even though it successfully opens the URL. Log the result of openURL and openURL:options:completionHandler and keep
           * moving forward for update.
           */
          MSACLogWarning([MSACDistribute logTag], @"System returned NO for update but processing.");
          break;
        }

        /*
         * On iOS 8.x and >= iOS 11.0 devices the update download doesn't start until the application goes in background by pressing home
         * button. Simply exit the app to start the update process. For iOS version >= 9.0 and < iOS 11.0, we still need to exit the app if
         * it is a mandatory update.
         */
        if ((floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_9_0) ||
            [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){11, 0, 0}] || details.mandatoryUpdate) {
          [self closeApp];
        }
      }];
}

- (void)closeApp __attribute__((noreturn)) {
  exit(0);
}

- (BOOL)openURL:(NSURL *)url {

  /*
   * Ignore if app secret not set, can't test scheme.
   * Also ignore if request is not for App Center Distribute and this app.
   */
  if (!self.appSecret || ![[url scheme] isEqualToString:[NSString stringWithFormat:kMSACDefaultCustomSchemeFormat, self.appSecret]]) {
    return NO;
  }

  // Process it if enabled.
  if ([self isEnabled]) {

    // Parse query parameters
    NSString *requestedId = [MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACUpdateTokenRequestIdKey];
    NSString *queryRequestId = nil;
    NSString *queryDistributionGroupId = nil;
    NSString *queryUpdateToken = nil;
    NSString *queryUpdateSetupFailed = nil;
    NSString *queryTesterAppUpdateSetupFailed = nil;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];

    // Read mandatory parameters from URL query string.
    for (NSURLQueryItem *item in components.queryItems) {
      if ([item.name isEqualToString:kMSACURLQueryRequestIdKey]) {
        queryRequestId = item.value;
      } else if ([item.name isEqualToString:kMSACURLQueryDistributionGroupIdKey]) {
        queryDistributionGroupId = item.value;
      } else if ([item.name isEqualToString:kMSACURLQueryUpdateTokenKey]) {
        queryUpdateToken = item.value;
      } else if ([item.name isEqualToString:kMSACURLQueryUpdateSetupFailedKey]) {
        queryUpdateSetupFailed = item.value;
      } else if ([item.name isEqualToString:kMSACURLQueryTesterAppUpdateSetupFailedKey]) {
        queryTesterAppUpdateSetupFailed = item.value;
      }
    }

    // If the request ID doesn't match, ignore.
    if (!(requestedId && queryRequestId && [requestedId isEqualToString:queryRequestId])) {
      return YES;
    }

    // Dismiss the embedded Safari view.
    [self dismissEmbeddedSafari];

    // Delete stored request ID.
    [MSAC_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSACUpdateTokenRequestIdKey];

    // Store distribution group ID.
    if (queryDistributionGroupId) {
      MSACLogDebug([MSACDistribute logTag], @"Distribution group ID has been successfully retrieved. Store the ID to storage.");
      [self processDistributionGroupId:queryDistributionGroupId];
    }

    /*
     * Check update token and store if exists.
     * Update token is used only for private distribution. If the query parameters don't include update token, it is public distribution.
     */
    if (queryUpdateToken) {
      MSACLogDebug([MSACDistribute logTag], @"Update token has been successfully retrieved. Store the token to secure storage.");

      // Storing the update token to keychain since the update token is considered as a sensitive information.
      [MSACKeychainUtil storeString:queryUpdateToken forKey:kMSACUpdateTokenKey];
    } else {
      [MSACKeychainUtil deleteStringForKey:kMSACUpdateTokenKey];
    }
    if (queryUpdateToken || queryDistributionGroupId) {
      [self checkLatestRelease:queryUpdateToken distributionGroupId:queryDistributionGroupId releaseHash:MSACPackageHash()];
    } else {
      MSACLogError([MSACDistribute logTag], @"Cannot find either update token or distribution group id.");
    }

    // If the in-app updates setup from the native tester app failed, retry using the browser update setup.
    if (queryTesterAppUpdateSetupFailed) {
      MSACLogDebug([MSACDistribute logTag], @"In-app updates setup from tester app failure detected.");
      [MSAC_APP_CENTER_USER_DEFAULTS setObject:queryTesterAppUpdateSetupFailed forKey:kMSACTesterAppUpdateSetupFailedKey];

      // Do not start update flow on start if automatic check is disabled.
      if (self.automaticCheckForUpdateDisabled) {
        MSACLogInfo([MSACDistribute logTag], @"Automatic checkForUpdate is disabled.");
        self.updateFlowInProgress = NO;
      } else {
        [self startUpdate];
      }
      return YES;
    }

    /*
     * If the in-app updates setup failed, and user ignores the failure, store the error message and also store the package hash that the
     * failure occurred on. The setup will only be re-attempted the next time the app gets updated (and package hash changes).
     */
    if (queryUpdateSetupFailed) {
      MSACLogDebug([MSACDistribute logTag], @"In-app updates setup failure detected.");
      [self showUpdateSetupFailedAlert:queryUpdateSetupFailed];
    }
  } else {
    MSACLogDebug([MSACDistribute logTag], @"Distribute service has been disabled, ignore request.");
  }
  return YES;
}

- (void)processDistributionGroupId:(NSString *)queryDistributionGroupId {

  // Storing the distribution group ID to storage.
  [MSAC_APP_CENTER_USER_DEFAULTS setObject:queryDistributionGroupId forKey:kMSACDistributionGroupIdKey];

  // Update distribution group ID which is added to logs.
  [self.distributeInfoTracker updateDistributionGroupId:queryDistributionGroupId];

  // Only if we have managed to retrieve the Distribution group ID we should update the distribution session count.
  NSString *latestSessionId = [[MSACSessionContext sharedInstance] sessionIdAt:[NSDate date]];

  // If Analytics SDK is disabled session Id is null and there is no need to update the distribution session count.
  if (latestSessionId) {
    [self sendFirstSessionUpdateLog];
  }
}

- (void)setUpdateTrack:(MSACUpdateTrack)updateTrack {
  @synchronized(self) {
    if (self.started) {
      MSACLogError([MSACDistribute logTag], @"Update track cannot be set after Distribute is started.");
      return;
    } else if (![MSACDistributeUtil isValidUpdateTrack:updateTrack]) {
      MSACLogError([MSACDistribute logTag], @"Invalid argument passed to updateTrack.");
      return;
    }
    _updateTrack = updateTrack;
  }
}

- (MSACUpdateTrack)updateTrack {
  @synchronized(self) {
    return _updateTrack;
  }
}

- (void)applicationDidBecomeActive {
  if (!self.canBeUsed || !self.isEnabled) {
    return;
  }
  if ([MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACUpdateTokenRequestIdKey]) {
    return;
  }
  if (self.automaticCheckForUpdateDisabled) {
    return;
  }
  [self startUpdate];
}

- (void)disableAutomaticCheckForUpdate {
  @synchronized(self) {
    if (self.started) {
      MSACLogError([MSACDistribute logTag], @"Cannot disable automatic check for updates after Distribute is started.");
      return;
    }
    self.automaticCheckForUpdateDisabled = YES;
  }
}

- (void)checkForUpdate {
  if (!self.canBeUsed || !self.isEnabled) {
    return;
  }
  if ([MSAC_APP_CENTER_USER_DEFAULTS objectForKey:kMSACUpdateTokenRequestIdKey]) {
    return;
  }
  MSACLogVerbose([MSACDistribute logTag], @"Manually checking for updates.");
  [self startUpdate];
}

- (void)dealloc {
  [MSAC_NOTIFICATION_CENTER removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

+ (void)resetSharedInstance {

  // Reset the onceToken so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
}

@end
