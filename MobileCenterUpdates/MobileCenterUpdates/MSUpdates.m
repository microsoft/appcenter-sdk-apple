/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "MSLogger.h"
#import "MSLogManager.h"
#import "MSMobileCenterInternal.h"
#import "MSUpdates.h"
#import "MSUpdatesInternal.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Updates";

// Base URL for HTTP login API calls.
static NSString *const kMSDefaultLoginUrl = @"http://install.asgard-int.trafficmanager.net/";

// Base URL for HTTP update API calls.
static NSString *const kMSDefaultUpdateUrl = @"https://asgard-int.trafficmanager.net/api";


@interface MSUpdates ()

@end

@implementation MSUpdates

#pragma mark - Public

+ (void)setLoginUrl:(NSString *)loginUrl {
  [[self sharedInstance] setLoginUrl:loginUrl];
}

+ (void)setUpdateUrl:(NSString *)updateUrl {
  [[self sharedInstance] setUpdateUrl:updateUrl];
}


#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _loginUrl = kMSDefaultLoginUrl;
    _updateUrl = kMSDefaultUpdateUrl;
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

- (void)startWithLogManager:(id <MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];
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

@end
