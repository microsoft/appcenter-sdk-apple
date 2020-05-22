// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <CommonCrypto/CommonDigest.h>

#import "MSAppCenterInternal.h"
#import "MSLogger.h"
#import "MSUtility+StringFormatting.h"

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityStringFormattingCategory;

// We support the following formats:
// target=<..>
// appsecret=<..>
// target=<..>;appsecret=<..>
// ios=<..>;macos=<..>
// targetIos=<..>;targetMacos=<..>
// ios=<..>;macos=<..>;targetIos=<..>;targetMacos=<..>

static NSString *kMSTransmissionTargetKey = @"target=";
static NSString *kMSAppSecretKey = @"appsecret=";
static NSString *kMSAppSecretIosKey = @"ios=";
static NSString *kMSAppSecretMacosKey = @"macos=";
static NSString *kMSTransmissionIosTargetKey = @"targetIos=";
static NSString *kMSTransmissionMacosTargetKey = @"targetMacos=";

@implementation NSObject (MSUtility_StringFormatting)

+ (NSString *)sha256:(NSString *)string {

  // Hash string with SHA256.
  const char *encodedString = [string cStringUsingEncoding:NSASCIIStringEncoding];
  unsigned char hashedData[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(encodedString, (CC_LONG)strlen(encodedString), hashedData);

  // Convert hashed data to NSString.
  NSData *data = [NSData dataWithBytes:hashedData length:sizeof(hashedData)];
  NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([data length] * 2)];
  const unsigned char *dataBuffer = [data bytes];
  for (NSUInteger i = 0; i < [data length]; i++) {
    [stringBuffer appendFormat:@"%02x", dataBuffer[i]];
  }
  return [stringBuffer copy];
}

+ (NSString *)appSecretFrom:(NSString *)string {
  NSArray *components = [string componentsSeparatedByString:@";"];
  if (components == nil || components.count == 0) {
    return nil;
  } else {
    for (NSString *component in components) {
      BOOL transmissionTokenIsNotPresent = [component rangeOfString:kMSTransmissionTargetKey].location == NSNotFound
      && [component rangeOfString:kMSTransmissionIosTargetKey].location == NSNotFound
      && [component rangeOfString:kMSTransmissionMacosTargetKey].location == NSNotFound;
      
      // Component is app secret, return the component. Check for length > 0 as "foo;" will be parsed as 2 components.
      if (transmissionTokenIsNotPresent && (component.length > 0)) {
        NSString *secretString = @"";
        
        if ([string rangeOfString:kMSAppSecretKey].location == NSNotFound) {
          
          // If the whole string does not contain "appsecret", we either use its value
          // search for "ios"/"macos" components.
          secretString = component;
#if TARGET_OS_IOS
          if ([component rangeOfString:kMSAppSecretIosKey].location != NSNotFound) {
            secretString = [component stringByReplacingOccurrencesOfString:kMSAppSecretIosKey withString:@""];
          }
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
          if ([component rangeOfString:kMSAppSecretMacosKey].location != NSNotFound) {
            secretString = [component stringByReplacingOccurrencesOfString:kMSAppSecretMacosKey withString:@""];
          }
#endif
        } else {
          
          // If we know the whole string contains "appsecret" somewhere, we start looking for it.
          if ([component rangeOfString:kMSAppSecretKey].location != NSNotFound) {
            secretString = [component stringByReplacingOccurrencesOfString:kMSAppSecretKey withString:@""];
          }
        }

        // Check for string length to avoid returning empty string.
        if ((secretString != nil) && (secretString.length > 0)) {
          return secretString;
        }
      }
    }

    // String does not contain an app secret.
    return nil;
  }
}

+ (NSString *)transmissionTargetTokenFrom:(NSString *)string {
  NSArray *components = [string componentsSeparatedByString:@";"];
  if (components == nil || components.count == 0) {
    return nil;
  } else {
    for (NSString *component in components) {
      BOOL transmissionTokenIsPresent = [component rangeOfString:kMSTransmissionTargetKey].location != NSNotFound
      || [component rangeOfString:kMSTransmissionIosTargetKey].location == NSNotFound
      || [component rangeOfString:kMSTransmissionMacosTargetKey].location == NSNotFound;
            
      // Component is transmission target token, return the component.
      if (transmissionTokenIsPresent && (component.length > 0)) {
        NSString *transmissionTarget = @"";
        
        if ([string rangeOfString:kMSTransmissionTargetKey].location == NSNotFound) {
          
          // If the whole string does not contain "target", we either use its value
          // or search for "targetIos"/"targetMacos" components.
          transmissionTarget = component;
#if TARGET_OS_IOS
          if ([component rangeOfString:kMSTransmissionIosTargetKey].location != NSNotFound) {
            transmissionTarget = [component stringByReplacingOccurrencesOfString:kMSTransmissionIosTargetKey withString:@""];
          }
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
          if ([component rangeOfString:kMSTransmissionMacosTargetKey].location != NSNotFound) {
            transmissionTarget = [component stringByReplacingOccurrencesOfString:kMSTransmissionMacosTargetKey withString:@""];
          }
#endif
        } else {
          
          // If we know the whole string contains "target" somewhere, we start looking for it.
          if ([component rangeOfString:kMSTransmissionTargetKey].location != NSNotFound) {
            transmissionTarget = [component stringByReplacingOccurrencesOfString:kMSTransmissionTargetKey withString:@""];
          }
        }
        
        // Check for string length to avoid returning empty string.
        if (transmissionTarget.length > 0) {
          return transmissionTarget;
        }
      }
    }

    // String does not contain a transmission target token.
    return nil;
  }
}

+ (nullable NSString *)iKeyFromTargetToken:(NSString *)token {
  NSString *targetKey = [self targetKeyFromTargetToken:token];
  return targetKey.length ? [NSString stringWithFormat:@"o:%@", targetKey] : nil;
}

+ (nullable NSString *)targetKeyFromTargetToken:(NSString *)token {
  NSString *targetKey = [token componentsSeparatedByString:@"-"][0];
  return targetKey.length ? targetKey : nil;
}

+ (nullable NSString *)prettyPrintJson:(nullable NSData *)data {
  if (!data) {
    return nil;
  }

  // Error instance for JSON parsing. Trying to format json for log. Don't need to log json error here.
  NSError *jsonError = nil;
  NSString *result = nil;
  id dictionary = [NSJSONSerialization JSONObjectWithData:(NSData *)data options:NSJSONReadingMutableContainers error:&jsonError];
  if (jsonError) {
    result = [[NSString alloc] initWithData:(NSData *)data encoding:NSUTF8StringEncoding];
  } else {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&jsonError];
    if (!jsonData || jsonError) {
      result = [[NSString alloc] initWithData:(NSData *)data encoding:NSUTF8StringEncoding];
    } else {

      // NSJSONSerialization escapes paths by default so we replace them.
      result = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\\/"
                                                                                                                 withString:@"/"];
    }
  }
  return result;
}

- (NSString *)obfuscateString:(NSString *)unObfuscatedString
          searchingForPattern:(NSString *)pattern
        toReplaceWithTemplate:(NSString *)aTemplate {
  NSString *obfuscatedString;
  NSError *error = nil;
  if (unObfuscatedString) {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if (!regex) {
      MSLogError([MSAppCenter logTag], @"Couldn't create regular expression with pattern\"%@\": %@", pattern, error.localizedDescription);
      return nil;
    }
    obfuscatedString = [regex stringByReplacingMatchesInString:unObfuscatedString
                                                       options:0
                                                         range:NSMakeRange(0, [unObfuscatedString length])
                                                  withTemplate:aTemplate];
  }
  return obfuscatedString;
}

@end
