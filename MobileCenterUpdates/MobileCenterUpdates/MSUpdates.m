/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSLogManager.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSUpdates.h"
#import "MSUpdatesPrivate.h"
#import "MSUtil.h"

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
 * Updates url paths.
 */
static NSString *const kMSUpdtDefaultURLTokenPath = @"/apps/%@/update-setup";

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
  MSLogInfo([MSUpdates logTag], @"Request updates token.");

  // Most failures here require an app update. Thus, it will be retried only on next App instance.
  @try {
    url = [self buildTokenRequestURLWithAppSecret:appSecret];

    // iOS 9+ only, check for SFSafariViewController availability.
    Class clazz = NSClassFromString(@"SFSafariViewController");
    if (clazz) {
      [self openURLInEmbeddedSafari:url fromClass:clazz];
    } else {

      // iOS 8.x.
      [self openURLInSafariApp:url];
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

- (NSURL *)buildTokenRequestURLWithAppSecret:(NSString *)appSecret{
  
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
  
  // FIXME: Workaround to fill in the app name required by the backend for now, supposed to be a build UUID.
  NSString *buildUUID = [MS_APP_MAIN_BUNDLE objectForInfoDictionaryKey:@"MSAppName"];
  //    NSString *buildUUID = [[MSFTCECodeSignatureExtractor forMainBundle] getUUIDHashHexStringAndReturnError:&error];
  //    if (error) {
  //      @throw [[NSException alloc] initWithName:kMSUpdtBuildIdExceptionName
  //                                        reason:[error localizedDescription]
  //                                      userInfo:nil];
  //    }
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
  
  // Check URL validity.
  if (!components.URL) {
    @throw [[NSException alloc] initWithName:kMSUpdtURLExceptionName
                                      reason:[NSString stringWithFormat:kMSUpdtURLExceptionReasonInvalid, components]
                                    userInfo:nil];
  }
  return components.URL;
}

- (void)openURLInEmbeddedSafari:(NSURL *)url fromClass:(Class) clazz{
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

@end
