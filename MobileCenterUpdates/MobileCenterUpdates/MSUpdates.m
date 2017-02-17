#import "MSDistributionSender.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSReleaseDetails.h"
#import "MSServiceAbstractProtected.h"
#import "MSUpdates.h"
#import "MSUpdatesPrivate.h"
#import "MSUpdatesInternal.h"
#import "MSUtil.h"

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Updates";

/**
 * The header name for update token
 */
static NSString *const kMSUpdtsHeaderApiToken = @"x-api-token";

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

#pragma mark - Exception constants

/**
 * Exceptions' names.
 */
static NSString *const kMSUpdtsURLExceptionName = @"UpdateURLFailure";
static NSString *const kMSUpdtsSchemeExceptionName = @"UpdateSchemeFailure";
static NSString *const kMSUpdtsBuildIdExceptionName = @"UpdateBuildIdFailure";

/**
 * Exceptions' reasons.
 */
static NSString *const kMSUpdtsURLExceptionReasonInvalid = @"Invalid Update URL:\n%@";
static NSString *const kMSUpdtsSchemeExceptionReasonNotFound = @"URL scheme for updates not found.";

@implementation MSUpdates

#pragma mark - Public

+ (void)setApiUrl:(NSString *)apiUrl {
  [[self sharedInstance] setApiUrl:apiUrl];
}

+ (void)setInstallUrl:(NSString *)installUrl {
  [[self sharedInstance] setInstallUrl:installUrl];
}

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _apiUrl = kMSDefaultApiUrl;
    _installUrl = kMSDefaultInstallUrl;
  }
  return self;
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

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];

  // TODO: Hook up with pipeline.
  NSURL *url;
  MSLogInfo([MSUpdates logTag], @"Request updates token.");

  // Most failures here require an app update. Thus, it will be retried only on next App instance.
  @try {
    url = [self buildTokenRequestURLWithAppSecret:appSecret];

    // iOS 9+ only, check for SFSafariViewController availability.
    Class clazz = NSClassFromString(@"SFSafariViewController");
    if (clazz) {
      
      // Manipulate App UI on the main queue.
      dispatch_async(dispatch_get_main_queue(), ^{
        [self openURLInEmbeddedSafari:url fromClass:clazz];
      });
    } else {

      // iOS 8.x.
      [self openURLInSafariApp:url];
    }
  } @catch (NSException *exception) {
    MSLogError([MSUpdates logTag], @"%@", exception.reason);
  }

  // TODO: Hook up with update token getter later.
  NSString *updateToken = @"temporary-token";
  self.sender =
      [[MSDistributionSender alloc] initWithBaseUrl:self.apiUrl
                                            apiPath:[NSString stringWithFormat:kMSUpdtsLatestReleaseApiPathFormat, appSecret]
                                            // TODO: Update token in header should be in format of "Bearer {JWT token}"
                                            headers:@{
                                              kMSUpdtsHeaderApiToken : updateToken
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

+ (NSString *)logTag {
  return @"MobileCenterUpdates";
}

- (void)checkLatestRelease {
  [self.sender sendAsync:nil
       completionHandler:^(NSString *callId, NSUInteger statusCode, NSData *data, NSError *error) {

         // Success.
         if (statusCode == MSHTTPCodesNo200OK) {
           MSReleaseDetails *details = [[MSReleaseDetails alloc]
               initWithDictionary:[NSJSONSerialization JSONObjectWithData:data
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:nil]];
           MSLogDebug([MSUpdates logTag], @"Received a response of update request: %@",
                      [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
           [self handleUpdate:details];
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

- (NSString *)storageKey {
  return kMSServiceName;
}

- (MSPriority)priority {
  return MSPriorityHigh;
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

  // Compute URL path string.
  NSString *urlPath = [NSString stringWithFormat:kMSUpdtsUpdateTokenApiPathFormat, appSecret];

  // Build URL string.
  NSString *urlString = [kMSDefaultInstallUrl stringByAppendingString:urlPath];
  NSURLComponents *components = [NSURLComponents componentsWithString:urlString];

  // Check URL validity so far.
  if (!components) {
    @throw [[NSException alloc] initWithName:kMSUpdtsURLExceptionName
                                      reason:[NSString stringWithFormat:kMSUpdtsURLExceptionReasonInvalid, urlString]
                                    userInfo:nil];
  }

  // Set URL query parameters.

  // FIXME: Workaround to fill in the app name required by the backend for now, supposed to be a build UUID.
  NSString *buildUUID = [MS_APP_MAIN_BUNDLE objectForInfoDictionaryKey:@"MSAppName"];
  //    NSString *buildUUID = [[MSFTCECodeSignatureExtractor forMainBundle] getUUIDHashHexStringAndReturnError:&error];
  //    if (error) {
  //      @throw [[NSException alloc] initWithName:kMSUpdtsBuildIdExceptionName
  //                                        reason:[error localizedDescription]
  //                                      userInfo:nil];
  //    }
  NSMutableArray *queryItems = [NSMutableArray array];
  if (![self checkURLSchemeRegistered:kMSUpdtsDefaultCustomScheme]) {
    @throw [[NSException alloc] initWithName:kMSUpdtsSchemeExceptionName
                                      reason:kMSUpdtsSchemeExceptionReasonNotFound
                                    userInfo:nil];
  }
  [queryItems addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryReleaseHashKey value:buildUUID]];
  [queryItems
      addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryRedirectIdKey value:kMSUpdtsDefaultCustomScheme]];
  [queryItems addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryRequestIdKey value:MS_UUID_STRING]];
  [queryItems
      addObject:[NSURLQueryItem queryItemWithName:kMSUpdtsURLQueryPlatformKey value:kMSUpdtsURLQueryPlatformValue]];
  components.queryItems = queryItems;

  // Check URL validity.
  if (!components.URL) {
    @throw [[NSException alloc] initWithName:kMSUpdtsURLExceptionName
                                      reason:[NSString stringWithFormat:kMSUpdtsURLExceptionReasonInvalid, components]
                                    userInfo:nil];
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
}

@end
