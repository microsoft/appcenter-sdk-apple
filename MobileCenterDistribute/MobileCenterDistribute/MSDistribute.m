#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>

#import "MSAlertController.h"
#import "MSBasicMachOParser.h"
#import "MSDistribute.h"
#import "MSDistributeInternal.h"
#import "MSDistributePrivate.h"
#import "MSDistributeSender.h"
#import "MSDistributeUtil.h"
#import "MSKeychainUtil.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSReleaseDetails.h"
#import "MSServiceAbstractProtected.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Distribute";

#pragma mark - URL constants

/**
 * Base URL for HTTP Distribute install API calls.
 */
static NSString *const kMSDefaultInstallUrl = @"http://install.asgard-int.trafficmanager.net";

/**
 * Base URL for HTTP Distribute update API calls.
 */
static NSString *const kMSDefaultApiUrl = @"https://asgard-int.trafficmanager.net/api/v0.1";

/**
 * The API path for update token request.
 */
static NSString *const kMSUpdateTokenApiPathFormat = @"/apps/%@/update-setup";

#pragma mark - Error constants

static NSString *const kMSUpdateTokenURLInvalidErrorDescFormat = @"Invalid update API token URL:%@";

@implementation MSDistribute

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _apiUrl = kMSDefaultApiUrl;
    _installUrl = kMSDefaultInstallUrl;

    /*
     * Delete API token if an application has been uninstalled and try to get a new one from server.
     * For iOS version < 10.3, keychain data won't be automatically deleted by uninstall
     * so we should detect it and clean up keychain data when Distribute service gets initialized.
     */
    NSNumber *flag = [MS_USER_DEFAULTS objectForKey:kMSSDKHasLaunchedWithDistribute];
    if (!flag) {
      MSLogInfo([MSDistribute logTag], @"Delete API token if exists.");
      [MSKeychainUtil deleteStringForKey:kMSUpdateTokenKey];
      [MS_USER_DEFAULTS setObject:@(1) forKey:kMSSDKHasLaunchedWithDistribute];
    }
  }
  return self;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (NSString *)logTag {
  return @"MobileCenterDistribute";
}

- (NSString *)storageKey {
  return kMSServiceName;
}

- (MSPriority)priority {
  return MSPriorityHigh;
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];

  // Enabling
  if (isEnabled) {
    MSLogInfo([MSDistribute logTag], @"Distribute service has been enabled.");
    NSString *updateToken = [MSKeychainUtil stringForKey:kMSUpdateTokenKey];
    if (updateToken) {
      [self checkLatestRelease:updateToken];
    } else {
      [self requestUpdateToken];
    }
  } else {
    [MS_USER_DEFAULTS removeObjectForKey:kMSUpdateTokenRequestIdKey];
    [MS_USER_DEFAULTS removeObjectForKey:kMSIgnoredReleaseIdKey];
    MSLogInfo([MSDistribute logTag], @"Distribute service has been disabled.");
  }
}

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];
  MSLogVerbose([MSDistribute logTag], @"Started Distribute service.");
}

#pragma mark - Public

+ (void)setApiUrl:(NSString *)apiUrl {
  [[self sharedInstance] setApiUrl:apiUrl];
}

+ (void)setInstallUrl:(NSString *)installUrl {
  [[self sharedInstance] setInstallUrl:installUrl];
}

+ (void)openUrl:(NSURL *)url {
  [[self sharedInstance] openUrl:url];
}

#pragma mark - Private

- (void)requestUpdateToken {

  // Check if it's okay to check for updates.
  if ([self checkForUpdatesAllowed]) {

    // Check if the device has internet connection to get update token.
    if ([MS_Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
      MSLogWarning(
          [MSDistribute logTag],
          @"The device lost its internet connection. The SDK will retry to get an update API token in the next launch.");
      return;
    }

    NSURL *url;
    MSLogInfo([MSDistribute logTag], @"Request Distribute API token.");

    // Most failures here require an app update. Thus, it will be retried only on next App instance.
    url = [self buildTokenRequestURLWithAppSecret:self.appSecret];
    if (url) {

/*
 * iOS 9+ only, check for `SFSafariViewController` availability. `SafariServices` framework MUST be weakly linked.
 * We can't use `NSClassFromString` here to avoid the warning.
 * It doesn't detect the class correctly unless the application explicitely imports the related framework.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
      Class clazz = [SFSafariViewController class];
#pragma clang diagnostic pop
      if (clazz) {

        // Manipulate App UI on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
          [self openURLInEmbeddedSafari:url fromClass:clazz];
        });
      } else {

        // iOS 8.x.
        [self openURLInSafariApp:url];
      }
    }
  } else {
    // Log a message to notify the user why the SDK didn't check for updates.
    MSLogDebug(
        [MSDistribute logTag],
        @"Distribute won't try to obtain an update token because of one of the following reasons: 1. A debugger is"
         "attached. 2. You are running the debug configuration. 3. The app is running in a non-adhoc environment."
         "Detach the debugger and restart the app and/or run the app with the release configuration to enable the"
         "feature.");
  }
}

- (void)checkLatestRelease:(NSString *)updateToken {

  // Check if it's okay to check for updates.
  if ([self checkForUpdatesAllowed]) {

    // Check if sender is still waiting for a response of the previous request.
    if (self.sender == nil) {
      self.sender =
          [[MSDistributeSender alloc] initWithBaseUrl:self.apiUrl appSecret:self.appSecret updateToken:updateToken];
      [self.sender
                  sendAsync:nil
          completionHandler:^(NSString *callId, NSUInteger statusCode, NSData *data, NSError *error) {

            // Release sender instance.
            self.sender = nil;

            // Ignore the response if the service is disabled.
            if (![self isEnabled]) {
              return;
            }

            // Success.
            if (statusCode == MSHTTPCodesNo200OK) {
              id dictionary =
                  [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
              MSReleaseDetails *details = [[MSReleaseDetails alloc] initWithDictionary:dictionary];
              if (!details) {
                MSLogError([MSDistribute logTag], @"Couldn't parse response payload.");
              } else {
                NSData *jsonData =
                    [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
                NSString *jsonString = nil;
                if (!jsonData || error) {
                  jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                } else {

                  // NSJSONSerialization escapes paths by default so we replace them.
                  jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]
                      stringByReplacingOccurrencesOfString:@"\\/"
                                                withString:@"/"];
                }
                MSLogDebug([MSDistribute logTag], @"Received a response of update request:\n%@", jsonString);
                [self handleUpdate:details];
              }
            }

            // Failure.
            else {
              MSLogDebug([MSDistribute logTag], @"Failed to get a update response, status code:%lu",
                         (unsigned long)statusCode);
              NSString *jsonString = nil;
              id dictionary =
                  [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];

              // Failure can deliver non-JSON format of payload.
              if (!error) {
                NSData *jsonData =
                    [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
                if (jsonData && !error) {

                  // NSJSONSerialization escapes paths by default so we replace them.
                  jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]
                      stringByReplacingOccurrencesOfString:@"\\/"
                                                withString:@"/"];
                }
              }
              MSLogError([MSDistribute logTag], @"Response:\n%@",
                         jsonString ? jsonString : [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            }
          }];
    }
  } else {

    // Log a message to notify the user why the SDK didn't check for updates.
    MSLogDebug(
        [MSDistribute logTag],
        @"Distribute won't check if a new release is available because of one of the following reasons: 1. A debugger "
         "is attached. 2. You are running the debug configuration. 3. The app is running in a non-adhoc environment."
         "Detach the debugger and restart the app and/or run the app with the release configuration to enable the"
         "feature.");
  }
}

#pragma mark - Private

- (BOOL)checkURLSchemeRegistered:(NSString *)urlScheme {
  NSArray *schemes;
  NSArray *types = [MS_APP_MAIN_BUNDLE objectForInfoDictionaryKey:@"CFBundleURLTypes"];
  for (NSDictionary *urlType in types) {
    schemes = urlType[@"CFBundleURLSchemes"];
    for (NSString *scheme in schemes) {
      if ([scheme isEqualToString:urlScheme]) {
        return YES;
      }
    }
  }
  return NO;
}

- (NSURL *)buildTokenRequestURLWithAppSecret:(NSString *)appSecret {

  // Create the request ID string.
  NSString *requestId = MS_UUID_STRING;

  // Compute URL path string.
  NSString *urlPath = [NSString stringWithFormat:kMSUpdateTokenApiPathFormat, appSecret];

  // Build URL string.
  NSString *urlString = [kMSDefaultInstallUrl stringByAppendingString:urlPath];
  NSURLComponents *components = [NSURLComponents componentsWithString:urlString];

  // Check URL validity so far.
  if (!components) {
    MSLogError([MSDistribute logTag], kMSUpdateTokenURLInvalidErrorDescFormat, urlString);
    return nil;
  }

  /*
   * BuildUUID is different on every build with code changes.
   * BuildUUID is used in this case as key prefix to get values from Safari cookies.
   * For testing purposes you can update the related Safari cookie keys to the BuildUUID of your choice
   * using JavaScript via Safari Web Inspector.
   */
  NSString *buildUUID = [[[MSBasicMachOParser machOParserForMainBundle].uuid UUIDString] lowercaseString];
  if (!buildUUID) {
    MSLogError([MSDistribute logTag], @"Cannot retrieve build UUID.");
    return nil;
  }

  // Check custom sheme is registered.
  NSString *scheme = [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, appSecret];
  if (![self checkURLSchemeRegistered:scheme]) {
    MSLogError([MSDistribute logTag], @"Custom URL scheme for Distribute not found.");
    return nil;
  }

  // Set URL query parameters.
  NSMutableArray *items = [NSMutableArray array];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSURLQueryReleaseHashKey value:buildUUID]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSURLQueryRedirectIdKey value:scheme]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSURLQueryRequestIdKey value:requestId]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSURLQueryPlatformKey value:kMSURLQueryPlatformValue]];
  components.queryItems = items;

  // Check URL validity.
  if (components.URL) {

    // Persist the request ID.
    [MS_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  } else {
    MSLogError([MSDistribute logTag], kMSUpdateTokenURLInvalidErrorDescFormat, components);
    return nil;
  }
  return components.URL;
}

- (void)openURLInEmbeddedSafari:(NSURL *)url fromClass:(Class)clazz {
  MSLogDebug([MSDistribute logTag], @"Using SFSafariViewController to open URL: %@", url);

  // Init safari controller with the install URL.
  id safari = [[clazz alloc] initWithURL:url];

  // Create an empty window + viewController to host the Safari UI.
  UIViewController *emptyViewController = [[UIViewController alloc] init];
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  window.rootViewController = emptyViewController;

  // Place it at the lowest level within the stack, less visible.
  window.windowLevel = -CGFLOAT_MAX;

  // Run it.
  [window makeKeyAndVisible];
  [emptyViewController presentViewController:safari animated:false completion:nil];
}

- (void)openURLInSafariApp:(NSURL *)url {
  MSLogDebug([MSDistribute logTag], @"Using Safari browser to open URL: %@", url);
  [MSUtil sharedAppOpenUrl:url options:@{} completionHandler:nil];
}

- (void)handleUpdate:(MSReleaseDetails *)details {

  // Step 1. Validate release details.
  if (![details isValid]) {
    MSLogError([MSDistribute logTag], @"Received invalid release details.");
    return;
  }

  // Step 2. Check status of the release. TODO: This will be deprecated soon.
  if (![details.status isEqualToString:@"available"]) {
    MSLogError([MSDistribute logTag], @"The new release is not available, skip update.");
    return;
  }

  // Step 3. Check if the release ID was ignored by a user.
  NSNumber *releaseId = [MS_USER_DEFAULTS objectForKey:kMSIgnoredReleaseIdKey];
  if (releaseId && releaseId == details.id) {
    MSLogDebug([MSDistribute logTag], @"A user already ignored updating this release, skip update.");
    return;
  }

  // Step 4. Check min OS version.
  if ([MS_DEVICE.systemVersion compare:details.minOs options:NSNumericSearch] == NSOrderedAscending) {
    MSLogDebug([MSDistribute logTag], @"The new release doesn't support this iOS version: %@, skip update.",
               MS_DEVICE.systemVersion);
    return;
  }

  // Step 5. Check version/hash to identify a newer version.
  if (![self isNewerVersion:details]) {
    MSLogDebug([MSDistribute logTag], @"The application is already up-to-date.");
    return;
  }

  // Step 6. Open a dialog and ask a user to choose options for the update.
  [self showConfirmationAlert:details];
}

- (BOOL)checkForUpdatesAllowed {

  // Check if we are not in AppStore or TestFlight environments.
  BOOL environmentOkay = [MSUtil currentAppEnvironment] == MSEnvironmentOther;

  // Check if a debugger is attached.
  BOOL noDebuggerAttached = ![MSMobileCenter isDebuggerAttached];

  // Make sure it's not a DEBUG configuration.
  BOOL configurationOkay = ![MSUtil isRunningInDebugConfiguration];

  return environmentOkay && noDebuggerAttached && configurationOkay;
}

- (BOOL)isNewerVersion:(MSReleaseDetails *)details {
  NSString *installedVersionUUID = [[[MSBasicMachOParser machOParserForMainBundle].uuid UUIDString] lowercaseString];
  NSArray<NSString *> *latestVersionUUIDs = details.packageHashes;
  return ![latestVersionUUIDs containsObject:installedVersionUUID];
}

- (void)showConfirmationAlert:(MSReleaseDetails *)details {

  // Displaying alert dialog. Running on main thread.
  dispatch_async(dispatch_get_main_queue(), ^{

    NSString *releaseNotes =
        details.releaseNotes ? details.releaseNotes : MSDistributeLocalizedString(@"No release notes");

    MSAlertController *alertController =
        [MSAlertController alertControllerWithTitle:MSDistributeLocalizedString(@"Update available")
                                            message:releaseNotes];

    // Add a "Ignore"-Button
    [alertController addDefaultActionWithTitle:MSDistributeLocalizedString(@"Ignore")
                                       handler:^(UIAlertAction *action) {
                                         MSLogDebug([MSDistribute logTag], @"Ignore the release id: %@.", details.id);
                                         [MS_USER_DEFAULTS setObject:details.id forKey:kMSIgnoredReleaseIdKey];
                                       }];

    // Add a "Postpone"-Button
    [alertController addCancelActionWithTitle:MSDistributeLocalizedString(@"Postpone")
                                      handler:^(UIAlertAction *action) {
                                        MSLogDebug([MSDistribute logTag], @"Postpone the release for now.");
                                      }];

    // Add a "Download"-Button
    [alertController addDefaultActionWithTitle:MSDistributeLocalizedString(@"Download")
                                       handler:^(UIAlertAction *action) {
                                         MSLogDebug([MSDistribute logTag], @"Start download and install the release.");
                                         [self startDownload:details];
                                       }];

    // Show the alert controller.
    MSLogDebug([MSDistribute logTag], @"Show update dialog.");
    [alertController show];
  });
}

- (void)startDownload:(MSReleaseDetails *)details {
#if TARGET_IPHONE_SIMULATOR
  MSLogWarning([MSDistribute logTag], @"Couldn't download a new release on simulator.");
#else
  [MSUtil sharedAppOpenUrl:details.installUrl
      options:@{}
      completionHandler:^(BOOL success) {
        if (success) {
          MSLogDebug([MSDistribute logTag], @"Start updating the application.");

          /*
           * We've seen the behavior on iOS 8.x devices in HockeyApp that it doesn't download until the application
           * goes in background by pressing home button. Simply exit the app to start the update process.
           */
          if (floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_9_0) {
            exit(0);
          }
        } else {
          MSLogError([MSDistribute logTag], @"System couldn't open the URL. Aborting update.");
        }
      }];
#endif
}

- (void)openUrl:(NSURL *)url {
  if ([self isEnabled]) {

    // If the request is not for Mobile Center Distribute, ignore.
    if (![[NSString stringWithFormat:kMSDefaultCustomSchemeFormat, self.appSecret] isEqualToString:[url scheme]]) {
      return;
    }

    // Parse query parameters
    NSString *requestedId = [MS_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey];
    NSString *queryRequestId = nil;
    NSString *queryUpdateToken = nil;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];

    // Read mandatory parameters from URL query string.
    for (NSURLQueryItem *item in components.queryItems) {
      if ([item.name isEqualToString:kMSURLQueryRequestIdKey]) {
        queryRequestId = item.value;
      } else if ([item.name isEqualToString:kMSURLQueryUpdateTokenKey]) {
        queryUpdateToken = item.value;
      }
    }

    // If the request ID doesn't match, ignore.
    if (!(requestedId && queryRequestId && [requestedId isEqualToString:queryRequestId])) {
      return;
    }

    // Delete stored request ID
    [MS_USER_DEFAULTS removeObjectForKey:kMSUpdateTokenRequestIdKey];

    // Store update token
    if (queryUpdateToken) {
      MSLogDebug([MSDistribute logTag],
                 @"Update token has been successfully retrieved. Store the token to secure storage.");

      // Storing the update token to keychain since the update token is considered as a sensitive information.
      [MSKeychainUtil storeString:queryUpdateToken forKey:kMSUpdateTokenKey];
      [self checkLatestRelease:queryUpdateToken];
    }
  } else {
    MSLogDebug([MSDistribute logTag], @"Distribute service has been disabled, ignore request.");
  }
}

@end
