// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>

#import "MSAppCenterInternal.h"
#import "MSAppDelegateForwarder.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSDependencyConfiguration.h"
#import "MSDistribute.h"
#import "MSDistributeAppDelegate.h"
#import "MSDistributeInternal.h"
#import "MSDistributePrivate.h"
#import "MSDistributeUtil.h"
#import "MSDistributionStartSessionLog.h"
#import "MSErrorDetails.h"
#import "MSGuidedAccessUtil.h"
#import "MSHttpClient.h"
#import "MSKeychainUtil.h"
#import "MSSessionContext.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Distribute";

/**
 * The group Id for storage.
 */
static NSString *const kMSGroupId = @"Distribute";

/**
 * Background task to save the browser connection.
 */
static UIBackgroundTaskIdentifier backgroundAuthSessionTask;

#pragma mark - URL constants

/**
 * The API path for update token request.
 */
static NSString *const kMSUpdateTokenApiPathFormat = @"/apps/%@/private-update-setup";

/**
 * The tester app path for update token request.
 */
static NSString *const kMSTesterAppUpdateTokenPath = @"ms-actesterapp://update-setup";

#pragma mark - Error constants

static NSString *const kMSUpdateTokenURLInvalidErrorDescFormat = @"Invalid update token URL:%@";

/**
 * Singleton.
 */
static MSDistribute *sharedInstance;

static dispatch_once_t onceToken;

@implementation MSDistribute

@synthesize channelUnitConfiguration = _channelUnitConfiguration;

@synthesize updateTrack = _updateTrack;

#pragma mark - Service initialization

- (instancetype)init {

  [MS_APP_CENTER_USER_DEFAULTS migrateKeys:@{
    @"MSAppCenterDistributeIsEnabled" : @"kMSDistributeIsEnabledKey", // [MSDistribute isEnabled]
    @"MSAppCenterPostponedTimestamp" : @"MSPostponedTimestamp",
    // [MSDistribute notifyUpdateAction],
    // [MSDistribute handleUpdate],
    // [MSDistribute checkLatestRelease]
    @"MSAppCenterSDKHasLaunchedWithDistribute" : @"MSSDKHasLaunchedWithDistribute",
    // [MSDistribute init],
    // [MSDistribute checkLatestRelease]
    @"MSAppCenterMandatoryRelease" : @"MSMandatoryRelease",
    // [MSDistribute checkLatestRelease],
    // [MSDistribute handleUpdate]
    @"MSAppCenterDistributionGroupId" : @"MSDistributionGroupId",
    // [MSDistribute startUpdateOnStart],
    // [MSDistribute processDistributionGroupId],
    // [MSDistribute changeDistributionGroupIdAfterAppUpdateIfNeeded]
    @"MSAppCenterUpdateSetupFailedPackageHash" : @"MSUpdateSetupFailedPackageHash",
    // [MSDistribute showUpdateSetupFailedAlert],
    // [MSDistribute requestInstallInformationWith]
    @"MSAppCenterDownloadedReleaseHash" : @"MSDownloadedReleaseHash",
    // [MSDistribute storeDownloadedReleaseDetails],
    // [MSDistribute removeDownloadedReleaseDetailsIfUpdated]
    @"MSAppCenterDownloadedReleaseId" : @"MSDownloadedReleaseId",
    // [MSDistribute getReportingParametersForUpdatedRelease],
    // [MSDistribute storeDownloadedReleaseDetails],
    // [MSDistribute removeDownloadedReleaseDetailsIfUpdated]
    @"MSAppCenterDownloadedDistributionGroupId" : @"MSDownloadedDistributionGroupId",
    // [MSDistribute changeDistributionGroupIdAfterAppUpdateIfNeeded],
    // [MSDistribute storeDownloadedReleaseDetails]
    @"MSAppCenterTesterAppUpdateSetupFailed" : @"MSTesterAppUpdateSetupFailed"
    // [MSDistribute showUpdateSetupFailedAlert],
    // [MSDistribute openUrl],
    // [MSDistribute requestInstallInformationWith]
  }
                                forService:kMSServiceName];
  if ((self = [super init])) {

    // Init.
    _apiUrl = kMSDefaultApiUrl;
    _installUrl = kMSDefaultInstallUrl;
    _channelUnitConfiguration = [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];
    _appDelegate = [MSDistributeAppDelegate new];

    /*
     * Delete update token if an application has been uninstalled and try to get a new one from server. For iOS version < 10.3, keychain
     * data won't be automatically deleted by uninstall so we should detect it and clean up keychain data when Distribute service gets
     * initialized.
     */
    NSNumber *flag = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSSDKHasLaunchedWithDistribute];
    if (!flag) {
      MSLogInfo([MSDistribute logTag], @"Delete update token if exists.");
      [MSKeychainUtil deleteStringForKey:kMSUpdateTokenKey];
      [MS_APP_CENTER_USER_DEFAULTS setObject:@1 forKey:kMSSDKHasLaunchedWithDistribute];
    }

    // Set a default value for update track.
    _updateTrack = MSUpdateTrackPublic;

    /*
     * Proceed update whenever an application is restarted in users perspective.
     * The SDK triggered update flow on UIApplicationWillEnterForeground but listening to UIApplicationDidBecomeActiveNotification
     * notification from version 3.0.0. It isn't reliable to make network calls on foreground so the SDK waits until the app has a
     * focus before making any network calls.
     */
    [MS_NOTIFICATION_CENTER addObserver:self
                               selector:@selector(applicationDidBecomeActive)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];

    // Init the distribute info tracker.
    _distributeInfoTracker = [[MSDistributeInfoTracker alloc] init];
  }
  return self;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    sharedInstance = [[MSDistribute alloc] init];
  });
  return sharedInstance;
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

+ (NSString *)logTag {
  return @"AppCenterDistribute";
}

- (NSString *)groupId {
  return kMSGroupId;
}

- (MSInitializationPriority)initializationPriority {

  // Initialize Distribute before Analytics to add distributionGroupId to the first startSession event after app starts.
  return MSInitializationPriorityHigh;
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];

  // Enabling
  if (isEnabled) {
    MSLogInfo([MSDistribute logTag], @"Distribute service has been enabled.");
    self.releaseDetails = nil;
    [[MSAppDelegateForwarder sharedInstance] addDelegate:self.appDelegate];

    // Enable the distribute info tracker.
    [self.channelGroup addDelegate:self.distributeInfoTracker];

    // Store distributionGroupId in distributeInfoTracker
    NSString *distributionGroupId = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSDistributionGroupIdKey];
    if (distributionGroupId) {
      MSLogDebug([MSDistribute logTag], @"Successfully retrieved distribution group Id setting it in distributeInfoTracker.");
      [self.distributeInfoTracker updateDistributionGroupId:distributionGroupId];
    }
    [self startUpdateOnStart:YES];
  } else {
    [self dismissEmbeddedSafari];
    [self.channelGroup removeDelegate:self.distributeInfoTracker];
    [[MSAppDelegateForwarder sharedInstance] removeDelegate:self.appDelegate];
    [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSUpdateTokenRequestIdKey];
    [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSPostponedTimestampKey];
    [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSMandatoryReleaseKey];
    [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSUpdateSetupFailedPackageHashKey];
    [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSTesterAppUpdateSetupFailedKey];
    MSLogInfo([MSDistribute logTag], @"Distribute service has been disabled.");
  }
}

- (void)notifyUpdateAction:(MSUpdateAction)action {

  @synchronized(self) {
    if (!self.releaseDetails) {
      MSLogDebug([MSDistribute logTag], @"The release has already been processed or update flow hasn't started yet.");
      self.updateFlowInProgress = NO;
      return;
    }
    if (!self.updateFlowInProgress) {
      MSLogInfo([MSDistribute logTag], @"There is no update flow in progress. Ignore the request.");
      self.releaseDetails = nil;
      return;
    }
    switch (action) {
    case MSUpdateActionUpdate:

      if ([self isEnabled]) {
        MSLogDebug([MSDistribute logTag], @"'Update now' is selected. Start download and install the update.");

        // Store details to report new download after restart if this release is installed.
        [self storeDownloadedReleaseDetails:self.releaseDetails];
#if TARGET_OS_SIMULATOR

        /*
         * iOS simulator doesn't support "itms-services" scheme, simulator will consider the scheme as an invalid address. Skip download
         * process if the application is running on simulator.
         */
        MSLogWarning([MSDistribute logTag], @"Couldn't download a new release on simulator.");
#else
        [self startDownload:self.releaseDetails];
#endif
      } else {
        MSLogDebug([MSDistribute logTag], @"'Update now' is selected but Distribute was disabled.");
        [self showDistributeDisabledAlert];
      }
      break;
    case MSUpdateActionPostpone:
      MSLogDebug([MSDistribute logTag], @"The SDK will ask for the update again tomorrow.");
      [MS_APP_CENTER_USER_DEFAULTS setObject:@((long long)[MSUtility nowInMilliseconds]) forKey:kMSPostponedTimestampKey];
      break;
    }

    // The release details have been processed. Clean up the variable.
    self.updateFlowInProgress = NO;
    self.releaseDetails = nil;
  }
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  if (appSecret) {
    id<MSHttpClientProtocol> httpClient = [MSDependencyConfiguration httpClient];
    if (!httpClient) {
      httpClient = [MSHttpClient new];
    }

    // Start Ingestion.
    self.ingestion = [[MSDistributeIngestion alloc] initWithHttpClient:httpClient
                                                               baseUrl:self.apiUrl
                                                             appSecret:(NSString * _Nonnull) appSecret];

    // Channel group should be started after Ingestion is ready.
    [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
    MSLogVerbose([MSDistribute logTag], @"Started Distribute service.");
  } else {
    MSLogError([MSDistribute logTag], @"Failed to start Distribute because app secret isn't specified.");
  }
}

#pragma mark - Public

+ (void)setApiUrl:(NSString *)apiUrl {
  [[MSDistribute sharedInstance] setApiUrl:apiUrl];
}

+ (void)setInstallUrl:(NSString *)installUrl {
  [[MSDistribute sharedInstance] setInstallUrl:installUrl];
}

+ (BOOL)openURL:(NSURL *)url {
  return [[MSDistribute sharedInstance] openURL:url];
}

+ (void)notifyUpdateAction:(MSUpdateAction)action {
  [[MSDistribute sharedInstance] notifyUpdateAction:action];
}

+ (void)setDelegate:(id<MSDistributeDelegate>)delegate {
  [[MSDistribute sharedInstance] setDelegate:delegate];
}

+ (void)setUpdateTrack:(MSUpdateTrack)updateTrack {
  [MSDistribute sharedInstance].updateTrack = updateTrack;
}

+ (MSUpdateTrack)updateTrack {
  return [MSDistribute sharedInstance].updateTrack;
}

+ (void)disableAutomaticCheckForUpdate {
  [[MSDistribute sharedInstance] disableAutomaticCheckForUpdate];
}

+ (void)checkForUpdate {
  [[MSDistribute sharedInstance] checkForUpdate];
}

#pragma mark - Private

- (void)sendFirstSessionUpdateLog {
  MSLogDebug([MSDistribute logTag], @"Updating the session count.");

  // log the first session after an install.
  MSDistributionStartSessionLog *log = [[MSDistributionStartSessionLog alloc] init];

  // Send log to log manager.
  [self.channelUnit enqueueItem:log flags:MSFlagsDefault];
}

- (void)startUpdateOnStart:(BOOL)onStart {

  // Do not start update flow on start if automatic check is disabled.
  if (onStart && self.automaticCheckForUpdateDisabled) {
    MSLogInfo([MSDistribute logTag], @"Automatic checkForUpdate is disabled.");
    self.updateFlowInProgress = NO;
    return;
  }

  NSString *releaseHash = MSPackageHash();
  if (releaseHash) {
    [self changeDistributionGroupIdAfterAppUpdateIfNeeded:releaseHash];
    OSStatus statusCode;
    NSString *updateToken = [MSKeychainUtil stringForKey:kMSUpdateTokenKey statusCode:&statusCode];
    if (statusCode == errSecInteractionNotAllowed) {
      MSLogError([MSDistribute logTag], @"Failed to get update token from keychain. This might occur when the device is locked.");
      return;
    }
    NSString *distributionGroupId = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSDistributionGroupIdKey];
    @synchronized(self) {
      if (self.updateFlowInProgress) {
        MSLogDebug([MSDistribute logTag], @"Previous update flow is in progress. Ignore the request.");
        return;
      }
      self.updateFlowInProgress = YES;
    }
    if (updateToken || self.updateTrack == MSUpdateTrackPublic) {
      [self checkLatestRelease:updateToken distributionGroupId:distributionGroupId releaseHash:releaseHash];
    } else {
      [self requestInstallInformationWith:releaseHash];
    }
  } else {
    MSLogError([MSDistribute logTag], @"Failed to get a release hash.");
  }
}

- (void)requestInstallInformationWith:(NSString *)releaseHash {

  // Check if it's okay to check for updates.
  if ([self checkForUpdatesAllowed]) {

    // Check if the device has internet connection to get update token.
    if ([MS_Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
      MSLogWarning([MSDistribute logTag],
                   @"The device lost its internet connection. The SDK will retry to get an update token in the next launch.");
      return;
    }

    /*
     * If failed to enable in-app updates on the same app build before, don't try again. Only if the app build is different (different
     * package hash), try enabling in-app updates again.
     */
    NSString *updateSetupFailedPackageHash = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSUpdateSetupFailedPackageHashKey];
    if (updateSetupFailedPackageHash) {
      if ([updateSetupFailedPackageHash isEqualToString:releaseHash]) {
        MSLogDebug([MSDistribute logTag], @"Skipping in-app updates setup, because it already failed on this release before.");
        return;
      } else {
        MSLogDebug([MSDistribute logTag], @"Re-attempting in-app updates setup and cleaning up failure info from storage.");
        [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSUpdateSetupFailedPackageHashKey];
        [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSTesterAppUpdateSetupFailedKey];
      }
    }

    // Create the request ID string and persist it.
    NSString *requestId = MS_UUID_STRING;
    [MS_APP_CENTER_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
    MSLogInfo([MSDistribute logTag], @"Request information of initial installation.");

    // Don't run on the UI thread, or else the app may be slow to startup.
    NSURL *testerAppUrl = [self buildTokenRequestURLWithAppSecret:self.appSecret releaseHash:releaseHash isTesterApp:true];
    NSURL *installUrl = [self buildTokenRequestURLWithAppSecret:self.appSecret releaseHash:releaseHash isTesterApp:false];
    dispatch_async(dispatch_get_main_queue(), ^{
      BOOL shouldUseTesterAppForUpdateSetup = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSTesterAppUpdateSetupFailedKey] == NULL;
      BOOL testerAppOpened = NO;
      if (shouldUseTesterAppForUpdateSetup) {
        MSLogInfo([MSDistribute logTag], @"Attempting to use tester app for update setup.");

        // Attempt to open the native iOS tester app to enable in-app updates.
        if (testerAppUrl) {
          testerAppOpened = [self openUrlUsingSharedApp:testerAppUrl];
          if (testerAppOpened) {
            MSLogInfo([MSDistribute logTag], @"Tester app was successfully opened to enable in-app updates.");
          } else {
            MSLogInfo([MSDistribute logTag], @"Tester app could not be opened to enable in-app updates (not installed?)");
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
    MSLogDebug([MSDistribute logTag], @"Distribute won't try to obtain an update token because of one of the following reasons: "
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
    if ([MS_Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
      MSReleaseDetails *details =
          [[MSReleaseDetails alloc] initWithDictionary:[MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSMandatoryReleaseKey]];
      if (details && ![self handleUpdate:details]) {

        // This release is no more a candidate for update, deleting it.
        [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSMandatoryReleaseKey];
      }
    }

    // Handle update.
    __weak typeof(self) weakSelf = self;
    MSSendAsyncCompletionHandler completionHandler =
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
          if (response.statusCode == MSHTTPCodesNo200OK) {
            MSReleaseDetails *details = nil;
            if (data) {
              id dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
              if (jsonError) {
                MSLogError([MSDistribute logTag], @"Couldn't parse json data: %@", jsonError.localizedDescription);
              }
              details = [[MSReleaseDetails alloc] initWithDictionary:dictionary];
            }
            if (!details) {
              MSLogError([MSDistribute logTag], @"Couldn't parse response payload.");
              strongSelf.updateFlowInProgress = NO;
            } else {

              // Check if downloaded release was installed and remove stored release details.
              [self removeDownloadedReleaseDetailsIfUpdated:releaseHash];

              // If there is not already a saved public distribution group, process it now.
              NSString *existingDistributionGroupId = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSDistributionGroupIdKey];
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
            MSLogError([MSDistribute logTag], @"Failed to get an update response, status code: %tu", response.statusCode);

            // Check the status code to clean up Distribute data for an unrecoverable error.
            if (![MSHttpUtil isRecoverableError:response.statusCode]) {

              // Deserialize payload to check if it contains error details.
              MSErrorDetails *details = nil;
              if (data) {
                id dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                if (dictionary) {
                  details = [[MSErrorDetails alloc] initWithDictionary:dictionary];
                }
              }

              // If the response payload is MSErrorDetails, consider it as a recoverable error.
              if (!details || ![kMSErrorCodeNoReleasesForUser isEqualToString:details.code]) {
                [MSKeychainUtil deleteStringForKey:kMSUpdateTokenKey];
                [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSSDKHasLaunchedWithDistribute];
                [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSUpdateTokenRequestIdKey];
                [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSPostponedTimestampKey];
                [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSDistributionGroupIdKey];
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
        [self getReportingParametersForUpdatedRelease:(self.updateTrack == MSUpdateTrackPublic)
                          currentInstalledReleaseHash:releaseHash
                                  distributionGroupId:distributionGroupId];
    if (reportingParametersForUpdatedRelease != nil) {
      [queryStrings addEntriesFromDictionary:reportingParametersForUpdatedRelease];
    }
    queryStrings[kMSURLQueryReleaseHashKey] = releaseHash;

    if (self.updateTrack == MSUpdateTrackPrivate) {
      if (updateToken) {
        [self.ingestion checkForPrivateUpdateWithUpdateToken:updateToken queryStrings:queryStrings completionHandler:completionHandler];
      } else {
        MSLogError([MSDistribute logTag], @"Update token is missing. Please authenticate Distribute first.");
      }
    } else {
      [self.ingestion checkForPublicUpdateWithQueryStrings:queryStrings completionHandler:completionHandler];
    }
  } else {

    // Log a message to notify the user why the SDK didn't check for updates.
    MSLogDebug([MSDistribute logTag], @"Distribute won't check if a new release is available because of one of the following reasons: "
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
  NSArray *types = [MS_APP_MAIN_BUNDLE objectForInfoDictionaryKey:kMSCFBundleURLTypes];
  for (NSDictionary *urlType in types) {
    schemes = urlType[kMSCFBundleURLSchemes];
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
  NSString *scheme = [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, appSecret];
  if (![self checkURLSchemeRegistered:scheme]) {
    MSLogError([MSDistribute logTag], @"Custom URL scheme for Distribute not found.");
    return nil;
  }

  // Build URL string.
  NSString *urlString;
  if (isTesterApp) {
    urlString = kMSTesterAppUpdateTokenPath;
  } else {
    NSString *urlPath = [NSString stringWithFormat:kMSUpdateTokenApiPathFormat, appSecret];
    urlString = [self.installUrl stringByAppendingString:urlPath];
  }
  NSURLComponents *components = [NSURLComponents componentsWithString:urlString];

  // Check URL validity so far.
  if (!components) {
    NSString *obfuscatedUrl = [urlString stringByReplacingOccurrencesOfString:appSecret withString:[MSHttpUtil hideSecret:urlString]];
    MSLogError([MSDistribute logTag], kMSUpdateTokenURLInvalidErrorDescFormat, obfuscatedUrl);
    return nil;
  }

  // Get the stored request ID, or create one if it doesn't exist yet.
  NSString *requestId = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey];
  if (!requestId) {
    requestId = MS_UUID_STRING;
    [MS_APP_CENTER_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  }

  // Set URL query parameters.
  NSMutableArray *items = [NSMutableArray array];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSURLQueryReleaseHashKey value:releaseHash]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSURLQueryRedirectIdKey value:scheme]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSURLQueryRequestIdKey value:requestId]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSURLQueryPlatformKey value:kMSURLQueryPlatformValue]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSURLQueryEnableUpdateSetupFailureRedirectKey value:@"true"]];
  components.queryItems = items;

  // Check URL validity.
  if (!components.URL) {
    MSLogError([MSDistribute logTag], kMSUpdateTokenURLInvalidErrorDescFormat, components);
    return nil;
  }
  return components.URL;
}

- (BOOL)openUrlUsingSharedApp:(NSURL *)url {
  UIApplication *sharedApp = [MSUtility sharedApp];
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
                                                                          withString:[MSHttpUtil hideSecret:url.absoluteString]];
  MSLogDebug([MSDistribute logTag], @"Using SFAuthenticationSession to open URL: %@", obfuscatedUrl);
  NSString *callbackUrlScheme = [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, self.appSecret];

  // The completion block that we need to invoke.
  __weak typeof(self) weakSelf = self;
  typedef void (^MSCompletionBlockForAuthSession)(NSURL *callbackUrl, NSError *error);
  MSCompletionBlockForAuthSession authCompletionBlock = ^(NSURL *callbackUrl, NSError *error) {
    typeof(self) strongSelf = weakSelf;
    if (!strongSelf) {
      [[MSUtility sharedApp] endBackgroundTask:backgroundAuthSessionTask];
      return;
    }
    if (error) {
      MSLogDebug([MSDistribute logTag], @"Called %@ with error: %@", callbackUrl, error.localizedDescription);
    }
    if (error.code == SFAuthenticationErrorCanceledLogin) {
      MSLogError([MSDistribute logTag], @"Authentication session was cancelled by user or failed.");
    }
    if (callbackUrl) {
      [strongSelf openURL:callbackUrl];
    } else {
      self.updateFlowInProgress = NO;
    }
    [[MSUtility sharedApp] endBackgroundTask:backgroundAuthSessionTask];
  };
  SFAuthenticationSession *session = [[SFAuthenticationSession alloc] initWithURL:url
                                                                callbackURLScheme:callbackUrlScheme
                                                                completionHandler:authCompletionBlock];

  // Calling 'start' on an existing session crashes the application - cancel session.
  [self.authenticationSession cancel];

  // Retain the session.
  self.authenticationSession = session;

  /*
   * Request additional background execution time for authorization. If we authorize using third-party services (MS Authenticator)
   * then switching to another application will kill the current session. This line fixes this problem.
   */
  backgroundAuthSessionTask = [[MSUtility sharedApp] beginBackgroundTaskWithName:@"Safari authentication"
                                                               expirationHandler:^{
                                                                 [[MSUtility sharedApp] endBackgroundTask:backgroundAuthSessionTask];
                                                               }];
  if ([session start]) {
    MSLogDebug([MSDistribute logTag], @"Authentication session started, showing confirmation dialog.");
  } else {
    MSLogError([MSDistribute logTag], @"Failed to start authentication session.");
    self.updateFlowInProgress = NO;
  }
}

- (void)openURLInSafariViewControllerWith:(NSURL *)url fromClass:(Class)clazz {
  MSLogDebug([MSDistribute logTag], @"Using SFSafariViewController to open URL: %@", url);
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

- (BOOL)handleUpdate:(MSReleaseDetails *)details {

  // Step 1. Validate release details.
  if (!details || ![details isValid]) {
    MSLogError([MSDistribute logTag], @"Received invalid release details.");
    return NO;
  }

  // Step 2. Check status of the release. TODO: This will be deprecated soon.
  if (![details.status isEqualToString:@"available"]) {
    MSLogError([MSDistribute logTag], @"The new release is not available, skip update.");
    return NO;
  }

  // Step 3. Check if the update is postponed by a user.
  NSNumber *postponedTimestamp = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSPostponedTimestampKey];
  if (postponedTimestamp) {
    long long duration = (long long)[MSUtility nowInMilliseconds] - [postponedTimestamp longLongValue];
    if (duration >= 0 && duration < kMSDayInMillisecond) {
      if (details.mandatoryUpdate) {
        MSLogDebug([MSDistribute logTag], @"The update was postponed within a day ago but the update is a mandatory update. The SDK will "
                                          @"proceed update for the release.");
      } else {
        MSLogDebug([MSDistribute logTag], @"The update was postponed within a day ago, skip update.");
        return NO;
      }
    }
    [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSPostponedTimestampKey];
  }

  // Step 4. Check min OS version.
  if ([MS_DEVICE.systemVersion compare:details.minOs options:NSNumericSearch] == NSOrderedAscending) {
    MSLogDebug([MSDistribute logTag], @"The new release doesn't support this iOS version: %@, skip update.", MS_DEVICE.systemVersion);
    return NO;
  }

  // Step 5. Check version/hash to identify a newer version.
  if (![self isNewerVersion:details]) {
    MSLogDebug([MSDistribute logTag], @"The application is already up-to-date.");
    return NO;
  }

  // Step 6. Persist this mandatory update to cover offline scenario.
  if (details.mandatoryUpdate) {

    // Persist this mandatory update now.
    [MS_APP_CENTER_USER_DEFAULTS setObject:[details serializeToDictionary] forKey:kMSMandatoryReleaseKey];
  } else {

    // Clean up mandatory release cache.
    [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSMandatoryReleaseKey];
  }

  // Step 7. Open a dialog and ask a user to choose options for the update.
  if (!self.releaseDetails || ![self.releaseDetails isEqual:details]) {
    self.releaseDetails = details;
    id<MSDistributeDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(distribute:releaseAvailableWithDetails:)]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        BOOL customized = [delegate distribute:self releaseAvailableWithDetails:details];
        MSLogDebug([MSDistribute logTag], @"releaseAvailableWithDetails delegate returned %@.", customized ? @"YES" : @"NO");
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
  BOOL compatibleEnvironment = [MSUtility currentAppEnvironment] == MSEnvironmentOther;

  // Check if we are currently in guided access mode. Guided access mode prevents opening update URLs.
  BOOL guidedAccessModeEnabled = [MSGuidedAccessUtil isGuidedAccessEnabled];

  // Check if a debugger is attached.
  BOOL debuggerAttached = [MSAppCenter isDebuggerAttached];
  return compatibleEnvironment && !debuggerAttached && !guidedAccessModeEnabled;
}

- (BOOL)isNewerVersion:(MSReleaseDetails *)details {
  return MSCompareCurrentReleaseWithRelease(details) == NSOrderedAscending;
}

- (void)storeDownloadedReleaseDetails:(nullable MSReleaseDetails *)details {
  if (details == nil) {
    MSLogDebug([MSDistribute logTag], @"Downloaded release details are missing or broken, won't store.");
    return;
  }
  NSString *groupId = details.distributionGroupId;
  NSNumber *releaseId = details.id;

  /*
   * IPA can contain several hashes, each for different architecture and we can't predict which will be installed, so save all hashes as
   * comma separated string.
   */
  NSString *releaseHashes = [details.packageHashes count] > 0 ? [details.packageHashes componentsJoinedByString:@","] : nil;
  [MS_APP_CENTER_USER_DEFAULTS setObject:groupId forKey:kMSDownloadedDistributionGroupIdKey];
  [MS_APP_CENTER_USER_DEFAULTS setObject:releaseId forKey:kMSDownloadedReleaseIdKey];
  [MS_APP_CENTER_USER_DEFAULTS setObject:releaseHashes forKey:kMSDownloadedReleaseHashKey];
  MSLogDebug([MSDistribute logTag], @"Stored downloaded release hash(es) (%@) and id (%@) for later reporting.", releaseHashes, releaseId);
}

- (void)removeDownloadedReleaseDetailsIfUpdated:(NSString *)currentInstalledReleaseHash {
  NSString *lastDownloadedReleaseHashes = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSDownloadedReleaseHashKey];
  if (lastDownloadedReleaseHashes == nil) {
    return;
  }
  if ([lastDownloadedReleaseHashes rangeOfString:currentInstalledReleaseHash].location == NSNotFound) {
    MSLogDebug([MSDistribute logTag],
               @"Stored release hash(es) (%@) doesn't match current installation hash (%@), "
               @"probably downloaded but not installed yet, keep in store.",
               lastDownloadedReleaseHashes, currentInstalledReleaseHash);
    return;
  }

  // Successfully reported, remove downloaded release details.
  MSLogDebug([MSDistribute logTag], @"Successfully reported app update for downloaded release hash (%@), removing from store.",
             currentInstalledReleaseHash);
  [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSDownloadedReleaseIdKey];
  [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSDownloadedReleaseHashKey];
}

- (nullable NSMutableDictionary *)getReportingParametersForUpdatedRelease:(BOOL)isPublic
                                              currentInstalledReleaseHash:(NSString *)currentInstalledReleaseHash
                                                      distributionGroupId:(NSString *)distributionGroupId {

  // Check if we need to report release installation.
  NSString *lastDownloadedReleaseHashes = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSDownloadedReleaseHashKey];
  if (lastDownloadedReleaseHashes == nil) {
    MSLogDebug([MSDistribute logTag], @"Current release was already reported, skip reporting.");
    return nil;
  }

  // Skip if downloaded release not installed yet.
  if ([lastDownloadedReleaseHashes rangeOfString:currentInstalledReleaseHash].location == NSNotFound) {
    MSLogDebug([MSDistribute logTag], @"New release was downloaded but not installed yet, skip reporting.");
    return nil;
  }

  // Return reporting parameters.
  MSLogDebug([MSDistribute logTag], @"Current release was updated but not reported yet, reporting.");
  NSMutableDictionary *reportingParameters = [[NSMutableDictionary alloc] init];
  reportingParameters[kMSURLQueryDistributionGroupIdKey] = distributionGroupId;
  if (isPublic) {
    reportingParameters[kMSURLQueryInstallIdKey] = [[MSAppCenter installId] UUIDString];
  }
  NSString *lastDownloadedReleaseId = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSDownloadedReleaseIdKey];
  reportingParameters[kMSURLQueryDownloadedReleaseIdKey] = lastDownloadedReleaseId;
  return reportingParameters;
}

- (void)changeDistributionGroupIdAfterAppUpdateIfNeeded:(NSString *)currentInstalledReleaseHash {
  NSString *updatedReleaseDistributionGroupId = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSDownloadedDistributionGroupIdKey];
  if (updatedReleaseDistributionGroupId == nil) {
    return;
  }

  // Skip if the current release was not updated.
  NSString *updatedReleaseHashes = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSDownloadedReleaseHashKey];
  if ((updatedReleaseHashes == nil) || ([updatedReleaseHashes rangeOfString:currentInstalledReleaseHash].location == NSNotFound)) {
    return;
  }

  // Skip if the group ID of an updated release is the same as the stored one.
  NSString *storedDistributionGroupId = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSDistributionGroupIdKey];
  if ((storedDistributionGroupId == nil) || ([updatedReleaseDistributionGroupId isEqualToString:storedDistributionGroupId] == NO)) {

    // Set group ID from downloaded release details if an updated release was downloaded from another distribution group.
    MSLogDebug([MSDistribute logTag], @"Stored group ID doesn't match the group ID of the updated release, updating group id: %@",
               updatedReleaseDistributionGroupId);
    [MS_APP_CENTER_USER_DEFAULTS setObject:updatedReleaseDistributionGroupId forKey:kMSDistributionGroupIdKey];
  }

  // Remove saved downloaded group ID.
  [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSDownloadedDistributionGroupIdKey];
}

- (void)showConfirmationAlert:(MSReleaseDetails *)details {

  // Displaying alert dialog. Running on main thread.
  dispatch_async(dispatch_get_main_queue(), ^{
    // Init the alert controller.
    NSString *messageFormat = details.mandatoryUpdate ? MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableMandatoryUpdateMessage")
                                                      : MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableOptionalUpdateMessage");
    NSString *appName = [MS_APP_MAIN_BUNDLE objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!appName) {
      appName = [MS_APP_MAIN_BUNDLE objectForInfoDictionaryKey:@"CFBundleName"];
    }

// FIXME: Format string should be a string literal but its format is in string resource so it won't be. Disable the warning temporarily.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
    NSString *message = [NSString stringWithFormat:messageFormat, appName, details.shortVersion, details.version];
#pragma clang diagnostic pop
    MSAlertController *alertController =
        [MSAlertController alertControllerWithTitle:MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailable") message:message];

    if (!details.mandatoryUpdate) {

      // Add a "Ask me in a day"-Button.
      [alertController addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                         handler:^(__attribute__((unused)) UIAlertAction *action) {
                                           [self notifyUpdateAction:MSUpdateActionPostpone];
                                         }];
    }

    if ([details.releaseNotes length] > 0 && details.releaseNotesUrl) {

      // Add a "View release notes"-Button.
      [alertController addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeViewReleaseNotes")
                                         handler:^(__attribute__((unused)) UIAlertAction *action) {
                                           MSLogDebug([MSDistribute logTag],
                                                      @"'View release notes' is selected. Open a browser and show release notes.");
                                           [MSUtility sharedAppOpenUrl:details.releaseNotesUrl options:@{} completionHandler:nil];

                                           /*
                                            * Clear release details so that the SDK can get the latest release again after coming back from
                                            * release notes.
                                            */
                                           self.releaseDetails = nil;
                                           self.updateFlowInProgress = NO;
                                         }];
    }

    // Add a "Update now"-Button.
    [alertController addPreferredActionWithTitle:MSDistributeLocalizedString(@"MSDistributeUpdateNow")
                                         handler:^(__attribute__((unused)) UIAlertAction *action) {
                                           [self notifyUpdateAction:MSUpdateActionUpdate];
                                         }];

    /*
     * Show the alert controller. It will replace any previous release alert. This happens when the network was down so the persisted
     * release was displayed but the network came back with a fresh release.
     */
    MSLogDebug([MSDistribute logTag], @"Show update dialog.");
    [alertController replaceAlert:self.updateAlertController];
    self.updateAlertController = alertController;
  });
}

- (void)showDistributeDisabledAlert {
  dispatch_async(dispatch_get_main_queue(), ^{
    MSAlertController *alertController =
        [MSAlertController alertControllerWithTitle:MSDistributeLocalizedString(@"MSDistributeInAppUpdatesAreDisabled") message:nil];
    [alertController addCancelActionWithTitle:MSDistributeLocalizedString(@"MSDistributeClose") handler:nil];
    [alertController show];
  });
}

- (void)showUpdateSetupFailedAlert:(NSString *)errorMessage {

  // Not using the error message coming from backend due to non-localized text.
  (void)errorMessage;
  dispatch_async(dispatch_get_main_queue(), ^{
    MSAlertController *alertController =
        [MSAlertController alertControllerWithTitle:MSDistributeLocalizedString(@"MSDistributeInAppUpdatesAreDisabled")
                                            message:MSDistributeLocalizedString(@"MSDistributeInstallFailedMessage")];

    // Add "Ignore" button to the dialog
    [alertController addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeIgnore")
                                       handler:^(__attribute__((unused)) UIAlertAction *action) {
                                         [MS_APP_CENTER_USER_DEFAULTS setObject:MSPackageHash() forKey:kMSUpdateSetupFailedPackageHashKey];
                                       }];

    // Add "Reinstall" button to the dialog
    [alertController
        addPreferredActionWithTitle:MSDistributeLocalizedString(@"MSDistributeReinstall")
                            handler:^(__attribute__((unused)) UIAlertAction *action) {
                              NSURL *installUrl = [NSURL URLWithString:[self installUrl]];

                              /*
                               * Add a flag to the install url to indicate that the update setup failed, to show a help page
                               */
                              NSURLComponents *components = [[NSURLComponents alloc] initWithURL:installUrl resolvingAgainstBaseURL:NO];
                              NSURLQueryItem *newQueryItem = [[NSURLQueryItem alloc] initWithName:kMSURLQueryUpdateSetupFailedKey
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
                              [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSTesterAppUpdateSetupFailedKey];
                              [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSUpdateSetupFailedPackageHashKey];
                            }];

    [alertController show];
  });
}

- (void)startDownload:(nullable MSReleaseDetails *)details {
  [MSUtility
       sharedAppOpenUrl:details.installUrl
                options:@{}
      completionHandler:^(MSOpenURLState state) {
        switch (state) {
        case MSOpenURLStateSucceed:
          MSLogDebug([MSDistribute logTag], @"Start updating the application.");
          break;
        case MSOpenURLStateFailed:
          MSLogError([MSDistribute logTag], @"System couldn't open the URL. Aborting update.");
          return;
        case MSOpenURLStateUnknown:

          /*
           * FIXME: We've observed a behavior in iOS 10+ that openURL and openURL:options:completionHandler don't say the operation is
           * succeeded even though it successfully opens the URL. Log the result of openURL and openURL:options:completionHandler and keep
           * moving forward for update.
           */
          MSLogWarning([MSDistribute logTag], @"System returned NO for update but processing.");
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
  if (!self.appSecret || ![[url scheme] isEqualToString:[NSString stringWithFormat:kMSDefaultCustomSchemeFormat, self.appSecret]]) {
    return NO;
  }

  // Process it if enabled.
  if ([self isEnabled]) {

    // Parse query parameters
    NSString *requestedId = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey];
    NSString *queryRequestId = nil;
    NSString *queryDistributionGroupId = nil;
    NSString *queryUpdateToken = nil;
    NSString *queryUpdateSetupFailed = nil;
    NSString *queryTesterAppUpdateSetupFailed = nil;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];

    // Read mandatory parameters from URL query string.
    for (NSURLQueryItem *item in components.queryItems) {
      if ([item.name isEqualToString:kMSURLQueryRequestIdKey]) {
        queryRequestId = item.value;
      } else if ([item.name isEqualToString:kMSURLQueryDistributionGroupIdKey]) {
        queryDistributionGroupId = item.value;
      } else if ([item.name isEqualToString:kMSURLQueryUpdateTokenKey]) {
        queryUpdateToken = item.value;
      } else if ([item.name isEqualToString:kMSURLQueryUpdateSetupFailedKey]) {
        queryUpdateSetupFailed = item.value;
      } else if ([item.name isEqualToString:kMSURLQueryTesterAppUpdateSetupFailedKey]) {
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
    [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSUpdateTokenRequestIdKey];

    // Store distribution group ID.
    if (queryDistributionGroupId) {
      MSLogDebug([MSDistribute logTag], @"Distribution group ID has been successfully retrieved. Store the ID to storage.");
      [self processDistributionGroupId:queryDistributionGroupId];
    }

    /*
     * Check update token and store if exists.
     * Update token is used only for private distribution. If the query parameters don't include update token, it is public distribution.
     */
    if (queryUpdateToken) {
      MSLogDebug([MSDistribute logTag], @"Update token has been successfully retrieved. Store the token to secure storage.");

      // Storing the update token to keychain since the update token is considered as a sensitive information.
      [MSKeychainUtil storeString:queryUpdateToken forKey:kMSUpdateTokenKey];
    } else {
      [MSKeychainUtil deleteStringForKey:kMSUpdateTokenKey];
    }
    if (queryUpdateToken || queryDistributionGroupId) {
      [self checkLatestRelease:queryUpdateToken distributionGroupId:queryDistributionGroupId releaseHash:MSPackageHash()];
    } else {
      MSLogError([MSDistribute logTag], @"Cannot find either update token or distribution group id.");
    }

    // If the in-app updates setup from the native tester app failed, retry using the browser update setup.
    if (queryTesterAppUpdateSetupFailed) {
      MSLogDebug([MSDistribute logTag], @"In-app updates setup from tester app failure detected.");
      [MS_APP_CENTER_USER_DEFAULTS setObject:queryTesterAppUpdateSetupFailed forKey:kMSTesterAppUpdateSetupFailedKey];
      [self startUpdateOnStart:YES];
      return YES;
    }

    /*
     * If the in-app updates setup failed, and user ignores the failure, store the error message and also store the package hash that the
     * failure occurred on. The setup will only be re-attempted the next time the app gets updated (and package hash changes).
     */
    if (queryUpdateSetupFailed) {
      MSLogDebug([MSDistribute logTag], @"In-app updates setup failure detected.");
      [self showUpdateSetupFailedAlert:queryUpdateSetupFailed];
    }
  } else {
    MSLogDebug([MSDistribute logTag], @"Distribute service has been disabled, ignore request.");
  }
  return YES;
}

- (void)processDistributionGroupId:(NSString *)queryDistributionGroupId {

  // Storing the distribution group ID to storage.
  [MS_APP_CENTER_USER_DEFAULTS setObject:queryDistributionGroupId forKey:kMSDistributionGroupIdKey];

  // Update distribution group ID which is added to logs.
  [self.distributeInfoTracker updateDistributionGroupId:queryDistributionGroupId];

  // Only if we have managed to retrieve the Distribution group ID we should update the distribution session count.
  NSString *latestSessionId = [[MSSessionContext sharedInstance] sessionIdAt:[NSDate date]];

  // If Analytics SDK is disabled session Id is null and there is no need to update the distribution session count.
  if (latestSessionId) {
    [self sendFirstSessionUpdateLog];
  }
}

- (void)setUpdateTrack:(MSUpdateTrack)updateTrack {
  @synchronized(self) {
    if (self.started) {
      MSLogError([MSDistribute logTag], @"Update track cannot be set after Distribute is started.");
      return;
    } else if (![MSDistributeUtil isValidUpdateTrack:updateTrack]) {
      MSLogError([MSDistribute logTag], @"Invalid argument passed to updateTrack.");
      return;
    }
    _updateTrack = updateTrack;
  }
}

- (MSUpdateTrack)updateTrack {
  @synchronized(self) {
    return _updateTrack;
  }
}

- (void)applicationDidBecomeActive {
  if (self.canBeUsed && self.isEnabled && ![MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey]) {
    [self startUpdateOnStart:YES];
  }
}

- (void)disableAutomaticCheckForUpdate {
  @synchronized(self) {
    if (self.started) {
      MSLogError([MSDistribute logTag], @"Cannot disable automatic check for updates after Distribute is started.");
      return;
    }
    self.automaticCheckForUpdateDisabled = YES;
  }
}

- (void)checkForUpdate {
  if (self.canBeUsed && self.isEnabled && ![MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey]) {
    [self startUpdateOnStart:NO];
  }
}

- (void)dealloc {
  [MS_NOTIFICATION_CENTER removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

+ (void)resetSharedInstance {

  // Reset the onceToken so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
}

@end
