#import <Foundation/Foundation.h>

#import "MSKeychainUtilPrivate.h"
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
  attributes[(__bridge id)kSecValueData] = [string dataUsingEncoding:NSUTF8StringEncoding];
  OSStatus status = [self addSecItem:attributes];
  return status == noErr;
}

+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key {
  return [MSKeychainUtil storeString:string forKey:key withServiceName:AppCenterKeychainServiceName(kMSServiceSuffix)];
}

+ (NSString *)deleteStringForKey:(NSString *)key withServiceName:(NSString *)serviceName {
  NSString *string = [MSKeychainUtil stringForKey:key];
  if (string) {
    NSMutableDictionary *query = [MSKeychainUtil generateItem:key withServiceName:serviceName];
    OSStatus status = [self deleteSecItem:query];
    if (status == noErr) {
      return string;
    }
  }
  return nil;
}

+ (NSString *)deleteStringForKey:(NSString *)key {
  return [MSKeychainUtil deleteStringForKey:key withServiceName:AppCenterKeychainServiceName(kMSServiceSuffix)];
}

+ (NSString *)stringForKey:(NSString *)key withServiceName:(NSString *)serviceName {
  NSMutableDictionary *query = [MSKeychainUtil generateItem:key withServiceName:serviceName];
  query[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
  query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
  CFTypeRef result = nil;
  OSStatus status = [self secItemCopyMatchingQuery:query result:&result];
  if (status == noErr) {
    return [[NSString alloc] initWithData:(__bridge_transfer NSData *)result encoding:NSUTF8StringEncoding];
  }
  return nil;
}

+ (NSString *)stringForKey:(NSString *)key {
  return [MSKeychainUtil stringForKey:key withServiceName:AppCenterKeychainServiceName(kMSServiceSuffix)];
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
