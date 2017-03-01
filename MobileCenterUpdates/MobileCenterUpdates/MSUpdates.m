#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>

#import "MSAlertController.h"
#import "MSBasicMachOParser.h"
#import "MSDistributionSender.h"
#import "MSKeychainUtil.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSReleaseDetails.h"
#import "MSServiceAbstractProtected.h"
#import "MSUpdates.h"
#import "MSUpdatesInternal.h"
#import "MSUpdatesPrivate.h"
#import "MSUpdatesUtil.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Updates";

#pragma mark - URL constants

/**
 * Base URL for HTTP Distribution install API calls.
 */
static NSString *const kMSDefaultInstallUrl = @"http://install.asgard-int.trafficmanager.net";

/**
 * Base URL for HTTP Distribution update API calls.
 */
static NSString *const kMSDefaultApiUrl = @"https://asgard-int.trafficmanager.net/api/v0.1";

/**
 * The API path for update token request.
 */
static NSString *const kMSUpdtsUpdateTokenApiPathFormat = @"/apps/%@/update-setup";

#pragma mark - Error constants

static NSString *const kMSUpdateTokenURLInvalidErrorDescFormat = @"Invalid update API token URL:%@";

@implementation MSUpdates

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _apiUrl = kMSDefaultApiUrl;
    _installUrl = kMSDefaultInstallUrl;
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
  return @"MobileCenterUpdates";
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
    MSLogInfo([MSUpdates logTag], @"Updates service has been enabled.");
    NSString *updateToken = [MSKeychainUtil stringForKey:kMSUpdateTokenKey];
    if (updateToken) {
      [self checkLatestRelease:updateToken];
    } else {
      [self requestUpdateToken];
    }
  } else {
    [MS_USER_DEFAULTS removeObjectForKey:kMSUpdateTokenRequestIdKey];
    [MS_USER_DEFAULTS removeObjectForKey:kMSIgnoredReleaseIdKey];
    MSLogInfo([MSUpdates logTag], @"Updates service has been disabled.");
  }
}

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];
  MSLogVerbose([MSUpdates logTag], @"Started Updates service.");

  // TODO remove this =)
  NSString *foo = MSUpdatesLocalizedString(@"Working");
  MSLogVerbose([MSUpdates logTag], @"%@", foo);
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
  NSURL *url;
  MSLogInfo([MSUpdates logTag], @"Request updates API token.");

  // Most failures here require an app update. Thus, it will be retried only on next App instance.
  url = [self buildTokenRequestURLWithAppSecret:self.appSecret];
  if (url) {

/*
 * iOS 9+ only, check for `SFSafariViewController` availability. `SafariServices` framework MUST be weakly linked.
 * We can't use `NSClassFromString` here to avoid the warning.
 * It doesn't detect the class correctly unless the application explicitely import the related framework.
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
}

- (void)checkLatestRelease:(NSString *)updateToken {
  MSDistributionSender *sender =
      [[MSDistributionSender alloc] initWithBaseUrl:self.apiUrl
                                            headers:@{
                                              kMSHeaderUpdateApiToken : updateToken
                                            }
                                       queryStrings:nil
                                       reachability:[MS_Reachability reachabilityForInternetConnection]
                                     retryIntervals:@[ @(10) ]];

  [sender sendAsync:nil
      completionHandler:^(NSString *callId, NSUInteger statusCode, NSData *data, NSError *error) {

        // Success.
        if (statusCode == MSHTTPCodesNo200OK) {
          id dictionary =
              [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
          MSReleaseDetails *details = [[MSReleaseDetails alloc] initWithDictionary:dictionary];
          if (!details) {
            MSLogError([MSUpdates logTag], @"Couldn't parse response payload.");
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
            MSLogDebug([MSUpdates logTag], @"Received a response of update request:\n%@", jsonString);
            [self handleUpdate:details];
          }
        }

        // Failure.
        else {
          MSLogDebug([MSUpdates logTag], @"Failed to get a update response, status code:%lu",
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
          MSLogError([MSUpdates logTag], @"Response:\n%@",
                     jsonString ? jsonString : [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }

        // There is no more interaction with distribution backend. Shutdown sender.
        [sender setEnabled:NO andDeleteDataOnDisabled:YES];
      }];
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
  NSString *urlPath = [NSString stringWithFormat:kMSUpdtsUpdateTokenApiPathFormat, appSecret];

  // Build URL string.
  NSString *urlString = [kMSDefaultInstallUrl stringByAppendingString:urlPath];
  NSURLComponents *components = [NSURLComponents componentsWithString:urlString];

  // Check URL validity so far.
  if (!components) {
    MSLogError([MSUpdates logTag], kMSUpdateTokenURLInvalidErrorDescFormat, urlString);
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
    MSLogError([MSUpdates logTag], @"Cannot retrieve build UUID.");
    return nil;
  }

  // Check custom sheme is registered.
  NSString *scheme = [NSString stringWithFormat:kMSUpdtsDefaultCustomSchemeFormat, appSecret];
  if (![self checkURLSchemeRegistered:scheme]) {
    MSLogError([MSUpdates logTag], @"Custom URL scheme for updates not found.");
    return nil;
  }

  // Set URL query parameters.
  NSMutableArray *items = [NSMutableArray array];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryReleaseHashKey value:buildUUID]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryRedirectIdKey value:scheme]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryRequestIdKey value:requestId]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryPlatformKey value:kMSUpdtsURLQueryPlatformValue]];
  components.queryItems = items;

  // Check URL validity.
  if (components.URL) {

    // Persist the request ID.
    [MS_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  } else {
    MSLogError([MSUpdates logTag], kMSUpdateTokenURLInvalidErrorDescFormat, components);
    return nil;
  }
  return components.URL;
}

- (void)openURLInEmbeddedSafari:(NSURL *)url fromClass:(Class)clazz {
  MSLogDebug([MSUpdates logTag], @"Using SFSafariViewController to open URL: %@", url);

  // Init safari controller with the update URL.
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
  MSLogDebug([MSUpdates logTag], @"Using Safari browser to open URL: %@", url);
  if ([MSUtil sharedAppCanOpenURL:url]) {
    [MSUtil sharedAppOpenURL:url];
  }
}

- (void)handleUpdate:(MSReleaseDetails *)details {

  // Step 1. Validate release details.
  if (![details isValid]) {
    MSLogError([MSUpdates logTag], @"Received invalid release details.");
    return;
  }

  // Step 2. Check status of the release. TODO: This will be deprecated soon.
  if (![details.status isEqualToString:@"available"]) {
    MSLogError([MSUpdates logTag], @"The new release is not available, skip update.");
    return;
  }

  // Step 3. Check if the release ID was ignored by a user.
  NSNumber *releaseId = [MS_USER_DEFAULTS objectForKey:kMSIgnoredReleaseIdKey];
  if (releaseId && releaseId == details.id) {
    MSLogDebug([MSUpdates logTag], @"A user already ignored updating this release, skip update.");
    return;
  }

  // Step 4. Check min OS version.
  if ([MS_DEVICE.systemVersion compare:details.minOs options:NSNumericSearch] == NSOrderedAscending) {
    MSLogDebug([MSUpdates logTag], @"The new release doesn't support this iOS version: %@, skip update.",
               MS_DEVICE.systemVersion);
    return;
  }

  // Step 5. Check version/hash to identify a newer version.
  if (![self isNewerVersion:details]) {
    MSLogDebug([MSUpdates logTag], @"The application is already up-to-date.");
    return;
  }

  // Step 6. Open a dialog and ask a user to choose options for the update.
  [self showConfirmationAlert:details];
}

- (BOOL)isAppFromAppStore {
  return [MSUtil currentAppEnvironment] == MSEnvironmentAppStore;
}

- (BOOL)isNewerVersion:(MSReleaseDetails *)details {
  NSString *installedVersionUUID = [[[MSBasicMachOParser machOParserForMainBundle].uuid UUIDString] lowercaseString];
  NSArray<NSString *> *latestVersionUUIDs = details.packageHashes;
  return ![latestVersionUUIDs containsObject:installedVersionUUID];
}

- (void)showConfirmationAlert:(MSReleaseDetails *)details {

  // Displaying alert dialog. Running on main thread.
  dispatch_async(dispatch_get_main_queue(), ^{

    // TODO: The text should be localized. There is a separate task for resources.
    NSString *releaseNotes =
        details.releaseNotes ? details.releaseNotes : @"No release notes were provided for this release.";

    MSAlertController *alertController =
        [MSAlertController alertControllerWithTitle:@"Update available" message:releaseNotes];

    // Add a "Ignore"-Button
    [alertController addDefaultActionWithTitle:@"Ignore"
                                       handler:^(UIAlertAction *action) {
                                         MSLogDebug([MSUpdates logTag], @"Ignore the release id: %@.", details.id);
                                         [MS_USER_DEFAULTS setObject:details.id forKey:kMSIgnoredReleaseIdKey];
                                       }];

    // Add a "Postpone"-Button
    [alertController addCancelActionWithTitle:@"Postpone"
                                      handler:^(UIAlertAction *action) {
                                        MSLogDebug([MSUpdates logTag], @"Postpone the release for now.");
                                      }];

    // Add a "Download"-Button
    [alertController addDefaultActionWithTitle:@"Download"
                                       handler:^(UIAlertAction *action) {
                                         MSLogDebug([MSUpdates logTag], @"Start download and install the release.");
                                         [self startDownload:details];
                                       }];

    // Show the alert controller.
    [alertController show];
  });
}

// TODO: Please implement!
- (void)startDownload:(MSReleaseDetails *)details {
}

- (void)openUrl:(NSURL *)url {
  if ([self isEnabled]) {

    // If the request is not for Mobile Center Updates, ignore.
    if (![[NSString stringWithFormat:kMSUpdtsDefaultCustomSchemeFormat, self.appSecret] isEqualToString:[url scheme]]) {
      return;
    }

    // Parse query parameters
    NSString *requestedId = [MS_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey];
    NSString *queryRequestId = nil;
    NSString *queryUpdateToken = nil;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];

    // Read mandatory parameters from URL query string.
    for (NSURLQueryItem *item in components.queryItems) {
      if ([item.name isEqualToString:kMSUpdtsURLQueryRequestIdKey]) {
        queryRequestId = item.value;
      } else if ([item.name isEqualToString:kMSUpdtsURLQueryUpdateTokenKey]) {
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
      MSLogDebug([MSUpdates logTag],
                 @"Update token has been successfully retrieved. Store the token to secure storage.");
      [MSKeychainUtil storeString:queryUpdateToken forKey:kMSUpdateTokenKey];
      [self checkLatestRelease:queryUpdateToken];
    }
  } else {
    MSLogDebug([MSUpdates logTag], @"Updates service has been disabled, ignore request.");
  }
}

@end
