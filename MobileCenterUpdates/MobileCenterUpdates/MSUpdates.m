/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSLogManager.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSUpdates.h"
#import "MSUtil.h"

#import <CodeSignatureExtraction/CodeSignatureExtraction.h> //TODO Better rewrite the code in objective c and use it directly.
#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Updates";

#pragma mark - URL constants

/**
 * Updates base url.
 */
static NSString *const kMSUpdtDefaultBaseURL =
    @"https://install.asgard-int.trafficmanager.net"; // TODO Update to prod https://install.mobile.azure.com

/**
 * Updates custom scheme.
 */
static NSString *const kMSUpdtDefaultCustomScheme = @"msupdt";

/**
 * Updates url paths.
 */
static NSString *const kMSUpdtDefaultURLTokenPath = @"/apps/%@/update-setup";

/**
 * Updates url query parameter key strings.
 */
static NSString *const kMSUpdtURLQueryPlatformKey = @"platform";
static NSString *const kMSUpdtURLQueryReleaseHashKey = @"release_hash";
static NSString *const kMSUpdtURLQueryRedirectIdKey = @"redirect_id";
static NSString *const kMSUpdtURLQueryRequestIdKey = @"request_id";

/**
 * Updates url query parameter value strings.
 */
static NSString *const kMSUpdtURLQueryPlatformValue = @"iOS";

#pragma mark - Exception constants

/**
 * Exceptions' names.
 */
static NSString *const kMSUpdtURLExceptionName = @"UpdateURLFailure";
static NSString *const kMSUpdtSchemeExceptionName = @"UpdateSchemeFailure";
static NSString *const kMSUpdtBuildIdExceptionName = @"UpdateBuildIdFailure";

/**
 * Exceptions' reasons.
 */
static NSString *const kMSUpdtURLExceptionReasonInvalid = @"Invalid Update URL:\n%@";
static NSString *const kMSUpdtSchemeExceptionReasonNotFound = @"URL scheme for updates not found.";

@implementation MSUpdates

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
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
  NSURL *url;
  NSError *error;

  // Most failures here require an app update. Thus, it will be retried only on next App instance.
  @try {

    // Compute URL path string.
    NSString *urlPath = [NSString stringWithFormat:kMSUpdtDefaultURLTokenPath, appSecret];

    // Build URL string.
    NSString *urlString = [kMSUpdtDefaultBaseURL stringByAppendingString:urlPath];
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];

    // Check URL validity so far.
    if (!components) {
      @throw [[NSException alloc] initWithName:kMSUpdtURLExceptionName
                                        reason:[NSString stringWithFormat:kMSUpdtURLExceptionReasonInvalid, urlString]
                                      userInfo:nil];
    }

    // Set URL query parameters.
    NSString *buildUUID = [[MSFTCECodeSignatureExtractor forMainBundle] getUUIDHashHexStringAndReturnError:&error];
    if (error) {
      @throw [[NSException alloc] initWithName:kMSUpdtBuildIdExceptionName
                                        reason:[error localizedDescription]
                                      userInfo:nil];
    }
    NSMutableArray *queryItems = [NSMutableArray array];
    if (![self checkURLSchemeRegistered:kMSUpdtDefaultCustomScheme]) {
      @throw [[NSException alloc] initWithName:kMSUpdtSchemeExceptionName
                                        reason:kMSUpdtSchemeExceptionReasonNotFound
                                      userInfo:nil];
    }
    [queryItems addObject:[NSURLQueryItem queryItemWithName:kMSUpdtURLQueryReleaseHashKey value:buildUUID]];
    [queryItems
        addObject:[NSURLQueryItem queryItemWithName:kMSUpdtURLQueryRedirectIdKey value:kMSUpdtDefaultCustomScheme]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:kMSUpdtURLQueryRequestIdKey value:MS_UUID_STRING]];
    [queryItems
        addObject:[NSURLQueryItem queryItemWithName:kMSUpdtURLQueryPlatformKey value:kMSUpdtURLQueryPlatformValue]];
    components.queryItems = queryItems;
    url = components.URL;

    // Check URL validity.
    if (!url) {
      @throw [[NSException alloc] initWithName:kMSUpdtURLExceptionName
                                        reason:[NSString stringWithFormat:kMSUpdtURLExceptionReasonInvalid, components]
                                      userInfo:nil];
    }

    // iOS 9+ only, check for SFSafariViewController availability.
    Class clazz = NSClassFromString(@"SFSafariViewController");
    if (clazz) {
      MSLogInfo([MSUpdates logTag], @"Using SFSafariViewController to request update token from URL: %@", url);

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
    } else {

      // iOS 8.x.
      MSLogInfo([MSUpdates logTag], @"Openning Safari browser to request update token from URL: %@", url);
      if ([MSUtil sharedAppCanOpenURL:url]) {
        [MSUtil sharedAppOpenURL:url];
      }
    }
  } @catch (NSException *exception) {
    MSLogError([MSUpdates logTag], @"%@", exception.reason);
  }
  MSLogVerbose([MSUpdates logTag], @"Started Updates service.");
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
@end
