#import <Foundation/Foundation.h>
#import "MSKeychainUtil.h"
#import "MSUtil.h"

@implementation MSKeychainUtil

NSString *MobileCenterKeychainServiceName(void) {
  static NSString *serviceName = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    serviceName = [NSString stringWithFormat:@"%@.MobileCenter", [MS_APP_MAIN_BUNDLE bundleIdentifier]];
  });
  return serviceName;
}

+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key {
  NSMutableDictionary *item = [MSKeychainUtil generateItem:key];
  item[(__bridge id)kSecValueData] = [string dataUsingEncoding:NSUTF8StringEncoding];

  OSStatus status = SecItemAdd((__bridge CFDictionaryRef)item, nil);
  return status == noErr;
}

+ (NSString *)deleteStringForKey:(NSString *)key {
  NSString *string = [MSKeychainUtil stringForKey:key];
  if (string) {
    NSMutableDictionary *item = [MSKeychainUtil generateItem:key];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)item);
    if (status == noErr) {
      return string;
    }
  }
  return nil;
}

+ (NSString *)stringForKey:(NSString *)key {
  NSMutableDictionary *item = [MSKeychainUtil generateItem:key];
  item[(__bridge id)kSecReturnData] = (id)kCFBooleanTrue;
  item[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

  CFTypeRef data = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)item, &data);

  if (status == noErr) {
    return [[NSString alloc] initWithData:(__bridge_transfer NSData *)data encoding:NSUTF8StringEncoding];
  }
  return nil;
}

+ (BOOL)clear {
  NSMutableDictionary *item = [NSMutableDictionary new];
  item[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
  item[(__bridge id)kSecAttrService] = MobileCenterKeychainServiceName();

  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)item);
  return status == noErr;
}

+ (NSMutableDictionary *)generateItem:(NSString *)key {
  NSMutableDictionary *item = [NSMutableDictionary new];
  item[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
  item[(__bridge id)kSecAttrService] = MobileCenterKeychainServiceName();
  item[(__bridge id)kSecAttrAccount] = key;
  return item;
}

@end
