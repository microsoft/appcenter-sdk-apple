// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.


#if GCC_PREPROCESSOR_MACRO_PUPPET
#import "AppCenter.h"
#import "AppCenterAnalytics.h"
#import "AppCenterAuth.h"
#import "AppCenterCrashes.h"
#import "AppCenterData.h"
#import "AppCenterDistribute.h"
#import "AppCenterPush.h"

// Internal
#import "MSAnalyticsInternal.h"
#import "MSAppCenterInternal.h"
#import "MSAuthPrivate.h"

#elif GCC_PREPROCESSOR_MACRO_SASQUATCH_OBJC
#import <AppCenter/AppCenter.h>
#import <AppCenterAnalytics/AppCenterAnalytics.h>
#import <AppCenterAuth/AppCenterAuth.h>
#import <AppCenterCrashes/AppCenterCrashes.h>
#import <AppCenterData/AppCenterData.h>
#import <AppCenterDistribute/AppCenterDistribute.h>
#import <AppCenterPush/AppCenterPush.h>
#else
@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterAuth;
@import AppCenterCrashes;
@import AppCenterData;
@import AppCenterDistribute;
@import AppCenterPush;
#endif

#import "AppCenterDelegateObjC.h"
#import "Constants.h"

/**
 * AppCenterDelegate implementation in Objective C.
 */
@implementation AppCenterDelegateObjC

#pragma mark - MSAppCenter section.

- (BOOL)isAppCenterEnabled {
  return [MSAppCenter isEnabled];
}

- (void)setAppCenterEnabled:(BOOL)isEnabled {
  [MSAppCenter setEnabled:isEnabled];
}

- (NSString *)installId {
  return [[MSAppCenter installId] UUIDString];
}

- (NSString *)appSecret {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  return [[MSAppCenter sharedInstance] appSecret];
#else
  return kMSObjcAppSecret;
#endif
}

- (NSString *)appSecretAAD {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  return kMSPuppetAADAppSecret;
#else
  return kMSSwiftObjcAADAppSecret;
#endif
}

- (NSString *)appSecretB2C {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  return kMSPuppetAppSecret;
#else
  return kMSObjcAppSecret;
#endif
}

- (NSString *)appSecretFirebase {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  return kMSPuppetFirebaseAppSecret;
#else
  return kMSSwiftObjcFirebaseAppSecret;
#endif
}

- (NSString *)appSecretAuth0 {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  return kMSPuppetAuth0AppSecret;
#else
  return kMSSwiftObjcAuth0AppSecret;
#endif
}

- (void)setLogUrl:(NSString *)logUrl {
  [MSAppCenter setLogUrl:logUrl];
}

- (NSString *)sdkVersion {
  return [MSAppCenter sdkVersion];
}

- (BOOL)isDebuggerAttached {
  return [MSAppCenter isDebuggerAttached];
}

- (void)setCustomProperties:(MSCustomProperties *)customProperties {
  [MSAppCenter setCustomProperties:customProperties];
}

- (void)startAnalyticsFromLibrary {
  [MSAppCenter startFromLibraryWithServices:@ [[MSAnalytics class]]];
}

- (void)setUserId:(NSString *)userId {
  [MSAppCenter setUserId:userId];
}

- (void)setCountryCode:(NSString *)countryCode {
  [MSAppCenter setCountryCode:countryCode];
}

- (void)setAuthToken:(NSString *)authToken {
  [MSAppCenter setAuthToken:authToken];
}

#pragma mark - Modules section.

- (BOOL)isAnalyticsEnabled {
  return [MSAnalytics isEnabled];
}

- (BOOL)isCrashesEnabled {
  return [MSCrashes isEnabled];
}

- (BOOL)isDistributeEnabled {
  return [MSDistribute isEnabled];
}

- (BOOL)isAuthEnabled {
  return [MSAuth isEnabled];
}

- (BOOL)isPushEnabled {
  return [MSPush isEnabled];
}

- (void)setAnalyticsEnabled:(BOOL)isEnabled {
  return [MSAnalytics setEnabled:isEnabled];
}

- (void)setCrashesEnabled:(BOOL)isEnabled {
  return [MSCrashes setEnabled:isEnabled];
}

- (void)setDistributeEnabled:(BOOL)isEnabled {
  return [MSDistribute setEnabled:isEnabled];
}

- (void)setAuthEnabled:(BOOL)isEnabled {
  return [MSAuth setEnabled:isEnabled];
}

- (void)setPushEnabled:(BOOL)isEnabled {
  return [MSPush setEnabled:isEnabled];
}

#pragma mark - MSAnalytics section.

- (void)trackEvent:(NSString *)eventName {
  [MSAnalytics trackEvent:eventName];
}

- (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary<NSString *, NSString *> *)properties {
  [MSAnalytics trackEvent:eventName withProperties:properties];
}

- (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary<NSString *, NSString *> *)properties flags:(MSFlags)flags {
  [MSAnalytics trackEvent:eventName withProperties:properties flags:flags];
}

- (void)trackEvent:(NSString *)eventName withTypedProperties:(MSEventProperties *)properties {
  [MSAnalytics trackEvent:eventName withTypedProperties:properties];
}

- (void)trackEvent:(NSString *)eventName withTypedProperties:(MSEventProperties *)properties flags:(MSFlags)flags {
  [MSAnalytics trackEvent:eventName withTypedProperties:properties flags:flags];
}

- (void)trackPage:(NSString *)pageName {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  [MSAnalytics trackPage:pageName];
#endif
}

- (void)trackPage:(NSString *)pageName withProperties:(NSDictionary<NSString *, NSString *> *)properties {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  [MSAnalytics trackPage:pageName withProperties:properties];
#endif
}

- (void)resume {
  [MSAnalytics resume];
}

- (void)pause {
  [MSAnalytics pause];
}

#pragma mark - MSCrashes section.

- (BOOL)hasCrashedInLastSession {
  return [MSCrashes hasCrashedInLastSession];
}

- (BOOL)hasReceivedMemoryWarningInLastSession {
  return [MSCrashes hasReceivedMemoryWarningInLastSession];
}

- (void)generateTestCrash {
  return [MSCrashes generateTestCrash];
}

#pragma mark - MSDistribute section.

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
- (void)showConfirmationAlert {
  MSReleaseDetails *releaseDetails = [MSReleaseDetails new];
  releaseDetails.version = @"10";
  releaseDetails.shortVersion = @"1.0";
  if ([MSDistribute respondsToSelector:@selector(sharedInstance)]) {
    id distributeInstance = [MSDistribute performSelector:@selector(sharedInstance)];
    if ([distributeInstance respondsToSelector:@selector(showConfirmationAlert:)]) {
      [distributeInstance performSelector:@selector(showConfirmationAlert:) withObject:releaseDetails];
    }
  }
}
#pragma clang diagnostic pop

- (void)showDistributeDisabledAlert {
  if ([MSDistribute respondsToSelector:@selector(sharedInstance)]) {
    id distributeInstance = [MSDistribute performSelector:@selector(sharedInstance)];
    if ([distributeInstance respondsToSelector:@selector(showDistributeDisabledAlert)]) {
      [distributeInstance performSelector:@selector(showDistributeDisabledAlert)];
    }
  }
}

- (void)showCustomConfirmationAlert {
  MSReleaseDetails *releaseDetails = [MSReleaseDetails new];
  releaseDetails.version = @"10";
  releaseDetails.shortVersion = @"1.0";
  if ([MSDistribute respondsToSelector:@selector(sharedInstance)]) {
    id distributeInstance = [MSDistribute performSelector:@selector(sharedInstance)];
    [[distributeInstance delegate] distribute:distributeInstance releaseAvailableWithDetails:releaseDetails];
  }
}

#pragma mark - MSAuth section.

- (void)signIn:(void (^)(MSUserInformation *_Nullable, NSError *))completionHandler {
  [MSAuth signInWithCompletionHandler:^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    if (!error) {
      NSLog(@"Auth.signIn succeeded, accountId=%@", userInformation.accountId);
    } else {
      NSLog(@"Auth.signIn failed, error=%@", error);
    }
    completionHandler(userInformation, error);
  }];
}

- (void)signOut {
  [MSAuth signOut];
}

#pragma mark - Last crash report section.

- (NSString *)lastCrashReportIncidentIdentifier {
  return [[MSCrashes lastSessionCrashReport] incidentIdentifier];
}

- (NSString *)lastCrashReportReporterKey {
  return [[MSCrashes lastSessionCrashReport] reporterKey];
}

- (NSString *)lastCrashReportSignal {
  return [[MSCrashes lastSessionCrashReport] signal];
}

- (NSString *)lastCrashReportExceptionName {
  return [[MSCrashes lastSessionCrashReport] exceptionName];
}

- (NSString *)lastCrashReportExceptionReason {
  return [[MSCrashes lastSessionCrashReport] exceptionReason];
}

- (NSString *)lastCrashReportAppStartTimeDescription {
  return [[[MSCrashes lastSessionCrashReport] appStartTime] description];
}

- (NSString *)lastCrashReportAppErrorTimeDescription {
  return [[[MSCrashes lastSessionCrashReport] appErrorTime] description];
}

- (NSUInteger)lastCrashReportAppProcessIdentifier {
  return [[MSCrashes lastSessionCrashReport] appProcessIdentifier];
}

- (BOOL)lastCrashReportIsAppKill {
  return [[MSCrashes lastSessionCrashReport] isAppKill];
}

- (NSString *)lastCrashReportDeviceModel {
  return [[[MSCrashes lastSessionCrashReport] device] model];
}

- (NSString *)lastCrashReportDeviceOemName {
  return [[[MSCrashes lastSessionCrashReport] device] oemName];
}

- (NSString *)lastCrashReportDeviceOsName {
  return [[[MSCrashes lastSessionCrashReport] device] osName];
}

- (NSString *)lastCrashReportDeviceOsVersion {
  return [[[MSCrashes lastSessionCrashReport] device] osVersion];
}

- (NSString *)lastCrashReportDeviceOsBuild {
  return [[[MSCrashes lastSessionCrashReport] device] osBuild];
}

- (NSString *)lastCrashReportDeviceLocale {
  return [[[MSCrashes lastSessionCrashReport] device] locale];
}

- (NSNumber *)lastCrashReportDeviceTimeZoneOffset {
  return [[[MSCrashes lastSessionCrashReport] device] timeZoneOffset];
}

- (NSString *)lastCrashReportDeviceScreenSize {
  return [[[MSCrashes lastSessionCrashReport] device] screenSize];
}

- (NSString *)lastCrashReportDeviceAppVersion {
  return [[[MSCrashes lastSessionCrashReport] device] appVersion];
}

- (NSString *)lastCrashReportDeviceAppBuild {
  return [[[MSCrashes lastSessionCrashReport] device] appBuild];
}

- (NSString *)lastCrashReportDeviceAppNamespace {
  return [[[MSCrashes lastSessionCrashReport] device] appNamespace];
}

- (NSString *)lastCrashReportDeviceCarrierName {
  return [[[MSCrashes lastSessionCrashReport] device] carrierName];
}

- (NSString *)lastCrashReportDeviceCarrierCountry {
  return [[[MSCrashes lastSessionCrashReport] device] carrierCountry];
}

// MSData section
- (void)listDocumentsWithPartition:(NSString *)partitionName
                      documentType:(Class)documentType
                 completionHandler:(void (^)(MSPaginatedDocuments *))completionHandler {
  [MSData listDocumentsWithType:documentType partition:partitionName completionHandler:completionHandler];
}

- (void)createDocumentWithPartition:(NSString *_Nonnull)partitionName
                         documentId:(NSString *_Nonnull)documentId
                           document:(MSDictionaryDocument *_Nonnull)document
                       writeOptions:(MSWriteOptions *_Nonnull)writeOptions
                  completionHandler:(void (^)(MSDocumentWrapper *))completionHandler {
  [MSData createDocumentWithID:documentId
                      document:document
                     partition:partitionName
                  writeOptions:writeOptions
             completionHandler:completionHandler];
}

- (void)deleteDocumentWithPartition:(NSString *_Nonnull)partitionName documentId:(NSString *_Nonnull)documentId {
  [MSData deleteDocumentWithID:documentId
                     partition:partitionName
             completionHandler:^(MSDocumentWrapper *_Nonnull document) {
               NSLog(@"Data.delete document with id %@ succeeded", documentId);
             }];
}

- (void)replaceDocumentWithPartition:(NSString *_Nonnull)partitionName
                          documentId:(NSString *_Nonnull)documentId
                            document:(MSDictionaryDocument *_Nonnull)document
                        writeOptions:(MSWriteOptions *_Nonnull)writeOptions
                   completionHandler:(void (^)(MSDocumentWrapper *))completionHandler {
  [MSData replaceDocumentWithID:documentId
                       document:document
                      partition:partitionName
                   writeOptions:writeOptions
              completionHandler:completionHandler];
}

- (void)readDocumentWithPartition:(NSString *_Nonnull)partitionName
                       documentId:(NSString *_Nonnull)documentId
                     documentType:(Class)documentType
                completionHandler:(void (^)(MSDocumentWrapper *))completionHandler {
  [MSData readDocumentWithID:documentId documentType:documentType partition:partitionName completionHandler:completionHandler];
}

@end
