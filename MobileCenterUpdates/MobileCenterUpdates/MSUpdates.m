#import <Foundation/Foundation.h>
#import "MSAlertController.h"
#import "MSDistributionSender.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSReleaseDetails.h"
#import "MSServiceAbstractProtected.h"
#import "MSUpdates.h"
#import "MSUpdatesInternal.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Updates";

/**
 * Base URL for HTTP Distribution install API calls.
 */
static NSString *const kMSDefaultInstallUrl = @"http://install.asgard-int.trafficmanager.net";

/**
 * Base URL for HTTP Distribution update API calls.
 */
static NSString *const kMSDefaultApiUrl = @"https://asgard-int.trafficmanager.net/api/v0.1";

/**
 * The API path for update request.
 */
static NSString *const kMSUpdatesApiPathFormat = @"/sdk/apps/%@/releases/latest";

/**
 * The header name for update token.
 */
static NSString *const kMSUpdatesHeaderApiToken = @"x-api-token";

/**
 * The key for ignored release ID.
 */
static NSString *const kMSIgnoredReleaseIdKey = @"MSIgnoredReleaseId";

@interface MSUpdates ()

@end

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

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityDefault;
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

  // TODO: Hook up with update token getter later.
  NSString *updateToken = @"050e55cf242247b694d3cfb43883d4531979751c";
  self.sender =
      [[MSDistributionSender alloc] initWithBaseUrl:self.apiUrl
                                            apiPath:[NSString stringWithFormat:kMSUpdatesApiPathFormat, appSecret]
                                            // TODO: Update token in header should be in format of "Bearer {JWT token}"
                                            headers:@{
                                              kMSUpdatesHeaderApiToken : updateToken
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
  if ([MS_DEVICE.systemVersion compare:details.minOs options:NSNumericSearch] != NSOrderedAscending) {
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
