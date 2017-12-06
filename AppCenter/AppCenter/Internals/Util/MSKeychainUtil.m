#import <Foundation/Foundation.h>

#import "MSKeychainUtilPrivate.h"
#import "MSUtility.h"

@implementation MSKeychainUtil

static NSString *AppCenterKeychainServiceName(NSString *suffix) {
  static NSString *serviceName = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    serviceName = [NSString stringWithFormat:@"%@.%@", suffix, [MS_APP_MAIN_BUNDLE bundleIdentifier]];
  });
  return serviceName;
}

+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key withServiceName:(NSString *)serviceName {
  NSMutableDictionary *item = [MSKeychainUtil generateItem:key withServiceName:serviceName];
  item[(__bridge id)kSecValueData] = [string dataUsingEncoding:NSUTF8StringEncoding];
  OSStatus status = SecItemAdd((__bridge CFDictionaryRef)item, nil);
  return status == noErr;
}

+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key {
  return [MSKeychainUtil storeString:string forKey:key withServiceName:AppCenterKeychainServiceName(kMSServiceSuffix)];
}

+ (NSString *)deleteStringForKey:(NSString *)key withServiceName:(NSString *)serviceName {
  NSString *string = [MSKeychainUtil stringForKey:key];
  if (string) {
    NSMutableDictionary *item = [MSKeychainUtil generateItem:key withServiceName:serviceName];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)item);
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
  NSMutableDictionary *item = [MSKeychainUtil generateItem:key withServiceName:serviceName];
  item[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
  item[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
  CFTypeRef data = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)item, &data);
  if (status == noErr) {
    return [[NSString alloc] initWithData:(__bridge_transfer NSData *)data encoding:NSUTF8StringEncoding];
  }
  return nil;
}

+ (NSString *)stringForKey:(NSString *)key {
  return [MSKeychainUtil stringForKey:key withServiceName:AppCenterKeychainServiceName(kMSServiceSuffix)];
}

+ (BOOL)clear {
  NSMutableDictionary *item = [NSMutableDictionary new];
  item[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
  item[(__bridge id)kSecAttrService] = AppCenterKeychainServiceName(kMSServiceSuffix);
  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)item);
  return status == noErr;
}

+ (NSMutableDictionary *)generateItem:(NSString *)key withServiceName:(NSString *)serviceName {
  NSMutableDictionary *item = [NSMutableDictionary new];
  item[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
  item[(__bridge id)kSecAttrService] = serviceName;
  item[(__bridge id)kSecAttrAccount] = key;
  return item;
}

@end
