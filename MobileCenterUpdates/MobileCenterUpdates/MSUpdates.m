/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "MSUpdates.h"
#import "MSLogger.h"
#import "MSDistributionSender.h"
#import "MSMobileCenterInternal.h"
#import "MSReleaseDetails.h"
#import "MSErrorDetails.h"
#import "MSServiceAbstractProtected.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Updates";

/**
 * Base URL for HTTP Distribution backend API calls.
 */
static NSString *const kMSDefaultBaseUrl = @"https://asgard-int.trafficmanager.net";

/**
 * The API path for update request.
 */
static NSString *const kMSUpdatesApiPathFormat = @"/api/sdk/apps/%@/releases/latest";

/**
 * The header name for update token
 */
static NSString *const kMSUpdatesHeaderApiToken = @"x-api-token";

@interface MSUpdates ()

@end

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

  // TODO: Hook up with update token getter later.
  NSString *updateToken = @"temporary-token";
  self.sender =
      [[MSDistributionSender alloc] initWithBaseUrl:kMSDefaultBaseUrl
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
       completionHandler:^(NSString *callId, NSError *error, NSUInteger statusCode, NSData *data) {

         // Success.
         if (statusCode == MSHTTPCodesNo200OK) {
           MSReleaseDetails *details = [[MSReleaseDetails alloc]
               initWithDictionary:[NSJSONSerialization JSONObjectWithData:data
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:nil]];
           MSLogDebug([MSUpdates logTag], @"Got a update response successfully.");
           [self handleUpdate:details];
         }

         // Failure.
         else {
           MSErrorDetails *details = [[MSErrorDetails alloc]
               initWithDictionary:[NSJSONSerialization JSONObjectWithData:data
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:nil]];
           MSLogDebug([MSUpdates logTag], @"Failed to get a update response, status code:%lu",
                      (unsigned long)statusCode);
           MSLogError([MSUpdates logTag], @"Error code: %@, message: %@", details.code, details.message);
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
