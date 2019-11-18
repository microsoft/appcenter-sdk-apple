// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenterInternal.h"
#import "MSKeychainUtilPrivate.h"
#import "MSLogger.h"
#import "MSUtility.h"

@implementation MSKeychainUtil

static NSString *AppCenterKeychainServiceName(NSString *suffix) {
  static NSString *serviceName = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    serviceName = [NSString stringWithFormat:@"%@.%@", [MS_APP_MAIN_BUNDLE bundleIdentifier], suffix];
  });
  return serviceName;
}

+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key withServiceName:(NSString *)serviceName {
  NSMutableDictionary *attributes = [MSKeychainUtil generateItem:key withServiceName:serviceName];

  // By default the keychain is not accessible when the device is locked, this will make it accessible after the first unlock.
  attributes[(__bridge id)kSecAttrAccessible] = (__bridge id)(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly);
  attributes[(__bridge id)kSecValueData] = [string dataUsingEncoding:NSUTF8StringEncoding];
  OSStatus status = [self addSecItem:attributes];

  // Delete item if already exists.
  if (status == errSecDuplicateItem) {
    [self deleteSecItem:attributes];
    status = [self addSecItem:attributes];
  }
  if (status == noErr) {
    MSLogVerbose([MSAppCenter logTag], @"Stored a string with key='%@', service='%@' to keychain.", key, serviceName);
    return YES;
  }
  MSLogWarning([MSAppCenter logTag], @"Failed to store item with key='%@', service='%@' to keychain. OS Status code %i", key, serviceName, status);
  return NO;
}

+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key {
  return [MSKeychainUtil storeString:string forKey:key withServiceName:AppCenterKeychainServiceName(kMSServiceSuffix)];
}

+ (NSString *)deleteStringForKey:(NSString *)key withServiceName:(NSString *)serviceName {
  NSString *string = [MSKeychainUtil stringForKey:key withStatusCode:nil];
  if (string) {
    NSMutableDictionary *query = [MSKeychainUtil generateItem:key withServiceName:serviceName];
    OSStatus status = [self deleteSecItem:query];
    if (status == noErr) {
      MSLogVerbose([MSAppCenter logTag], @"Deleted a string with key='%@', service='%@' from keychain.", key, serviceName);
      return string;
    }
    MSLogWarning([MSAppCenter logTag], @"Failed to delete item with key='%@', service='%@' from keychain. OS Status code %i", key, serviceName, status);
  }
  return nil;
}

+ (NSString *)deleteStringForKey:(NSString *)key {
  return [MSKeychainUtil deleteStringForKey:key withServiceName:AppCenterKeychainServiceName(kMSServiceSuffix)];
}

+ (NSString *)stringForKey:(NSString *)key withServiceName:(NSString *)serviceName withStatusCode:(OSStatus *)statusCode {
  NSMutableDictionary *query = [MSKeychainUtil generateItem:key withServiceName:serviceName];
  query[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
  query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
  CFTypeRef result = nil;

  // Create placeholder to use in case given status code pointer is NULL. Can't put it inside the if statement or it can get deallocated too
  // early.
  OSStatus statusPlaceholder;
  if (!statusCode) {
    statusCode = &statusPlaceholder;
  }
  *statusCode = [self secItemCopyMatchingQuery:query result:&result];
  if (*statusCode == noErr) {
    MSLogVerbose([MSAppCenter logTag], @"Retrieved a string with key='%@', service='%@' from keychain.", key, serviceName);
    return [[NSString alloc] initWithData:(__bridge_transfer NSData *)result encoding:NSUTF8StringEncoding];
  }
  MSLogWarning([MSAppCenter logTag], @"Failed to retrieve item with key='%@', service='%@' from keychain. OS Status code %i", key, serviceName, *statusCode);
  return nil;
}

+ (NSString *)stringForKey:(NSString *)key withStatusCode:(OSStatus *)statusCode {
  return [MSKeychainUtil stringForKey:key withServiceName:AppCenterKeychainServiceName(kMSServiceSuffix) withStatusCode:statusCode];
}

+ (BOOL)clear {
  NSMutableDictionary *query = [NSMutableDictionary new];
  query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
  query[(__bridge id)kSecAttrService] = AppCenterKeychainServiceName(kMSServiceSuffix);
  OSStatus status = [self deleteSecItem:query];
  return status == noErr;
}

+ (NSMutableDictionary *)generateItem:(NSString *)key withServiceName:(NSString *)serviceName {
  NSMutableDictionary *item = [NSMutableDictionary new];
  item[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
  item[(__bridge id)kSecAttrService] = serviceName;
  item[(__bridge id)kSecAttrAccount] = key;
  return item;
}

#pragma mark - Keychain wrapper

+ (OSStatus)deleteSecItem:(NSMutableDictionary *)query {
  return SecItemDelete((__bridge CFDictionaryRef)query);
}

+ (OSStatus)addSecItem:(NSMutableDictionary *)attributes {
  return SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
}

+ (OSStatus)secItemCopyMatchingQuery:(NSMutableDictionary *)query result:(CFTypeRef *__nullable CF_RETURNS_RETAINED)result {
  return SecItemCopyMatching((__bridge CFDictionaryRef)query, result);
}

@end
