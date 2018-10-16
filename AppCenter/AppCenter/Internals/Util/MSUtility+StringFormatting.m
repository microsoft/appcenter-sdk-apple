#import <CommonCrypto/CommonDigest.h>

#import "MSUtility+StringFormatting.h"

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityStringFormattingCategory;

static NSString *kMSTransmissionTargetKey = @"target=";
static NSString *kMSAppSecretKey = @"appsecret=";

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

      // Component is app secret, return the component. Check for length > 0 as "foo;" will be parsed as 2 components.
      if (([component rangeOfString:kMSTransmissionTargetKey].location == NSNotFound) && (component.length > 0)) {
        NSString *secretString = [component stringByReplacingOccurrencesOfString:kMSAppSecretKey withString:@""];

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

      // Component is transmission target token, return the component.
      if (([component rangeOfString:kMSTransmissionTargetKey].location != NSNotFound) && (component.length > 0)) {
        NSString *transmissionTarget = [component stringByReplacingOccurrencesOfString:kMSTransmissionTargetKey withString:@""];

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

@end
