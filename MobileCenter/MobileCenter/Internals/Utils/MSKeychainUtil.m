//
//  SFHFKeychainUtils.m
//
//  Created by Buzz Andersen on 10/20/08.
//  Based partly on code by Jonathan Wight, Jon Crosby, and Mike Malone.
//  Copyright 2008 Sci-Fi Hi-Fi. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

@import Foundation;
#import "MSKeychainUtil.h"

@implementation MSKeychainUtil

+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key service:(NSString *)serviceName {
  NSMutableDictionary *item = [MSKeychainUtil generateItem:key service:serviceName];
  item[(__bridge id) kSecValueData] = [string dataUsingEncoding:NSUTF8StringEncoding];

  OSStatus status = SecItemAdd((__bridge CFDictionaryRef) item, nil);
  return status == noErr;
}

+ (NSString *)deleteStringForKey:(NSString *)key service:(NSString *)serviceName {
  NSString *string = [MSKeychainUtil stringForKey:key service:serviceName];
  if (string) {
    NSMutableDictionary *item = [MSKeychainUtil generateItem:key service:serviceName];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef) item);
    if (status == noErr) {
      return string;
    }
  }

  return nil;
}

+ (NSString *)stringForKey:(NSString *)key service:(NSString *)serviceName {
  NSMutableDictionary *item = [MSKeychainUtil generateItem:key service:serviceName];
  item[(__bridge id) kSecReturnData] = (id) kCFBooleanTrue;
  item[(__bridge id) kSecMatchLimit] = (__bridge id) kSecMatchLimitOne;

  CFTypeRef data = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) item, &data);

  if (status == noErr) {
    return [[NSString alloc] initWithData:(__bridge_transfer NSData *) data encoding:NSUTF8StringEncoding];
  }

  return nil;
}

+ (BOOL)clearForService:(NSString *)serviceName {
  NSMutableDictionary *item = [NSMutableDictionary new];
  item[(__bridge id) kSecClass] = (__bridge id) kSecClassGenericPassword;
  item[(__bridge id) kSecAttrService] = serviceName;

  OSStatus status = SecItemDelete((__bridge CFDictionaryRef) item);
  return status == noErr;
}

+ (NSMutableDictionary *)generateItem:(NSString *)key service:(NSString *)serviceName {
  NSMutableDictionary *item = [NSMutableDictionary new];
  item[(__bridge id) kSecClass] = (__bridge id) kSecClassGenericPassword;
  item[(__bridge id) kSecAttrService] = serviceName;
  item[(__bridge id) kSecAttrAccount] = key;
  return item;
}

@end
