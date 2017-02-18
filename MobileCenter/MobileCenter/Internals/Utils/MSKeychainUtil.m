#import <Foundation/Foundation.h>
#import "MSKeychainUtil.h"

@implementation MSKeychainUtil

static NSString *const kMSDefaultServiceName = @"com.microsoft.azure.mobile.mobilecenter";

+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key {
  return [MSKeychainUtil storeString:string forKey:key service:kMSDefaultServiceName];
}

+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key service:(NSString *)serviceName {
  NSMutableDictionary *item = [MSKeychainUtil generateItem:key service:serviceName];
  item[(__bridge id)kSecValueData] = [string dataUsingEncoding:NSUTF8StringEncoding];

  OSStatus status = SecItemAdd((__bridge CFDictionaryRef)item, nil);
  return status == noErr;
}

+ (NSString *)deleteStringForKey:(NSString *)key {
  return [MSKeychainUtil deleteStringForKey:key service:kMSDefaultServiceName];
}

+ (NSString *)deleteStringForKey:(NSString *)key service:(NSString *)serviceName {
  NSString *string = [MSKeychainUtil stringForKey:key service:serviceName];
  if (string) {
    NSMutableDictionary *item = [MSKeychainUtil generateItem:key service:serviceName];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)item);
    if (status == noErr) {
      return string;
    }
  }

  return nil;
}

+ (NSString *)stringForKey:(NSString *)key {
  return [MSKeychainUtil stringForKey:key service:kMSDefaultServiceName];
}

+ (NSString *)stringForKey:(NSString *)key service:(NSString *)serviceName {
  NSMutableDictionary *item = [MSKeychainUtil generateItem:key service:serviceName];
  item[(__bridge id)kSecReturnData] = (id)kCFBooleanTrue;
  item[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

  CFTypeRef data = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)item, &data);

  if (status == noErr) {
    return [[NSString alloc] initWithData:(__bridge_transfer NSData *)data encoding:NSUTF8StringEncoding];
  }

  return nil;
}

+ (BOOL)clearForService {
  return [MSKeychainUtil clearForService:kMSDefaultServiceName];
}

+ (BOOL)clearForService:(NSString *)serviceName {
  NSMutableDictionary *item = [NSMutableDictionary new];
  item[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
  item[(__bridge id)kSecAttrService] = serviceName;

  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)item);
  return status == noErr;
}

+ (NSMutableDictionary *)generateItem:(NSString *)key service:(NSString *)serviceName {
  NSMutableDictionary *item = [NSMutableDictionary new];
  item[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
  item[(__bridge id)kSecAttrService] = serviceName;
  item[(__bridge id)kSecAttrAccount] = key;
  return item;
}

@end
