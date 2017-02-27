#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>

#import "MSAlertController.h"
#import "MSDistributionSender.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSReleaseDetails.h"
#import "MSServiceAbstractProtected.h"
#import "MSUpdates.h"
#import "MSUpdatesErrors.h"
#import "MSUpdatesInternal.h"
#import "MSUpdatesPrivate.h"
#import "MSUtil.h"
#import "MSBasicMachOParser.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Updates";

/**
 * Update API token storage key.
 */
static NSString *const kMSUpdateTokenRequestIdKey = @"MSUpdateTokenRequestId";

/**
 * The header name for update token.
 */
static NSString *const kMSHeaderUpdateApiToken = @"x-api-token";

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
 * The API path for latest release request.
 */
static NSString *const kMSUpdtsLatestReleaseApiPathFormat = @"/sdk/apps/%@/releases/latest";

/**
 * The API path for update token request.
 */
static NSString *const kMSUpdtsUpdateTokenApiPathFormat = @"/apps/%@/update-setup";

/**
 * The key for ignored release ID.
 */
static NSString *const kMSIgnoredReleaseIdKey = @"MSIgnoredReleaseId";

#pragma mark - Exception constants

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
  } else {
    MSLogInfo([MSUpdates logTag], @"Updates service has been disabled.");
  }
}

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];

  // TODO: Hook up with pipeline.
  NSURL *url;
  NSError *error = nil;
  MSLogInfo([MSUpdates logTag], @"Request updates API token.");

  // Most failures here require an app update. Thus, it will be retried only on next App instance.
  url = [self buildTokenRequestURLWithAppSecret:appSecret error:&error];
  if (!error) {

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
  } else {
    MSLogError([MSUpdates logTag], @"%@", error.localizedDescription);
  }

  // TODO: Hook up with update token getter later.
  NSString *updateToken = @"temporary-token";
  self.sender = [[MSDistributionSender alloc]
      initWithBaseUrl:self.apiUrl
              apiPath:[NSString stringWithFormat:kMSUpdtsLatestReleaseApiPathFormat, appSecret]
              // TODO: Update token in header should be in format of "Bearer {JWT token}"
              headers:@{
                kMSHeaderUpdateApiToken : updateToken
              }
         queryStrings:nil
         reachability:[MS_Reachability reachabilityForInternetConnection]
       retryIntervals:@[ @(10) ]];
  MSLogVerbose([MSUpdates logTag], @"Started Updates service.");

  if ([self isEnabled]) {
    [self checkLatestRelease];
  } else {
    MSLogDebug([MSUpdates logTag], @"Updates service is disabled, skip update.");
  }
}

#pragma mark - Public

+ (void)setApiUrl:(NSString *)apiUrl {
  [[self sharedInstance] setApiUrl:apiUrl];
}

+ (void)setInstallUrl:(NSString *)installUrl {
  [[self sharedInstance] setInstallUrl:installUrl];
}

#pragma mark - Private

- (void)checkLatestRelease {
  [self.sender sendAsync:nil
       completionHandler:^(NSString *callId, NSUInteger statusCode, NSData *data, NSError *error) {

         // Success.
         if (statusCode == MSHTTPCodesNo200OK) {
           MSReleaseDetails *details = [[MSReleaseDetails alloc]
               initWithDictionary:[NSJSONSerialization JSONObjectWithData:data
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:nil]];
           if (!details) {
             MSLogError([MSUpdates logTag], @"Couldn't parse response payload.");
           } else {
             MSLogDebug([MSUpdates logTag], @"Received a response of update request: %@",
                        [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
             [self handleUpdate:details];
           }
         }

         // Failure.
         else {
           MSLogDebug([MSUpdates logTag], @"Failed to get a update response, status code:%lu",
                      (unsigned long)statusCode);

           // TODO: Print formatted json response.
           MSLogError([MSUpdates logTag], @"Response: %@",
                      [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
         }

         // There is no more interaction with distribution backend. Shutdown sender.
         [self.sender setEnabled:NO andDeleteDataOnDisabled:YES];
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

- (NSURL *)buildTokenRequestURLWithAppSecret:(NSString *)appSecret error:(NSError *__autoreleasing *)error {

  // Create the request ID string.
  NSString *requestId = MS_UUID_STRING;

  // Compute URL path string.
  NSString *urlPath = [NSString stringWithFormat:kMSUpdtsUpdateTokenApiPathFormat, appSecret];

  // Build URL string.
  NSString *urlString = [kMSDefaultInstallUrl stringByAppendingString:urlPath];
  NSURLComponents *components = [NSURLComponents componentsWithString:urlString];

  // Check URL validity so far.
  if (!components) {
    if (error) {
      NSString *desc = [NSString stringWithFormat:@"%@\n%@", kMSUDUpdateTokenURLInvalidErrorDesc, components];
      *error = [NSError errorWithDomain:kMSUDErrorDomain
                                   code:kMSUDUpdateTokenURLInvalidErrorCode
                               userInfo:@{NSLocalizedDescriptionKey : desc}];
    }
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
    // TODO print error.
    return nil;
  }

  // Check custom sheme is registered.
  if (![self checkURLSchemeRegistered:kMSUpdtsDefaultCustomScheme]) {
    if (error) {
      *error = [NSError errorWithDomain:kMSUDErrorDomain
                                   code:kMSUDUpdateTokenSchemeNotFoundErrorCode
                               userInfo:@{NSLocalizedDescriptionKey : kMSUDUpdateTokenSchemeNotFoundErrorDesc}];
    }
    return nil;
  }

  // Set URL query parameters.
  NSMutableArray *items = [NSMutableArray array];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryReleaseHashKey value:buildUUID]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryRedirectIdKey value:kMSUpdtsDefaultCustomScheme]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryRequestIdKey value:requestId]];
  [items addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryPlatformKey value:kMSUpdtsURLQueryPlatformValue]];
  components.queryItems = items;

  // Check URL validity.
  if (components.URL) {

    // Persist the request ID.
    [MS_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  } else {
    if (error) {
      NSString *desc = [NSString stringWithFormat:@"%@\n%@", kMSUDUpdateTokenURLInvalidErrorDesc, components];
      *error = [NSError errorWithDomain:kMSUDErrorDomain
                                   code:kMSUDUpdateTokenURLInvalidErrorCode
                               userInfo:@{NSLocalizedDescriptionKey : desc}];
    }
    return nil;
  }
  return components.URL;
}

- (void)openURLInEmbeddedSafari:(NSURL *)url fromClass:(Class)clazz {
  MSLogVerbose([MSUpdates logTag], @"Using SFSafariViewController to open URL: %@", url);

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
  MSLogVerbose([MSUpdates logTag], @"Using Safari browser to open URL: %@", url);
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
  NSString *releaseId = [[MSUserDefaults shared] objectForKey:kMSIgnoredReleaseIdKey];
  if (releaseId && [releaseId isEqualToString:details.id]) {
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

// TODO: Please implement!
- (BOOL)isNewerVersion:(MSReleaseDetails *)details {
  return YES;
}

- (void)showConfirmationAlert:(MSReleaseDetails *)details {

  // TODO: The text should be localized. There is a separate task for resources.
  NSString *releaseNotes =
      details.releaseNotes ? details.releaseNotes : @"No release notes were provided for this release.";

  MSAlertController *alertController =
      [MSAlertController alertControllerWithTitle:@"Update available" message:releaseNotes];

  // Add a "Ignore"-Button
  [alertController addDefaultActionWithTitle:@"Ignore"
                                     handler:^(UIAlertAction *action) {
                                       MSLogDebug([MSUpdates logTag], @"Ignore the release id: %@.", details.id);
                                       [[MSUserDefaults shared] setObject:details.id forKey:kMSIgnoredReleaseIdKey];
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
}

// TODO: Please implement!
- (void)startDownload:(MSReleaseDetails *)details {
}

@end
