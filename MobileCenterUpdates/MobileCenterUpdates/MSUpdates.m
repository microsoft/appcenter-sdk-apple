#import <Foundation/Foundation.h>
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
 * The header name for update token
 */
static NSString *const kMSUpdatesHeaderApiToken = @"x-api-token";

@interface MSUpdates ()

@end

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

  // TODO: Hook up with update token getter later.
  NSString *updateToken = @"temporary-token";
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

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityDefault;
}

- (void)handleUpdate:(MSReleaseDetails *)details {
}

@end
