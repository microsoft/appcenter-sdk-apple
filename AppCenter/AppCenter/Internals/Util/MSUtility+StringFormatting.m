#import <CommonCrypto/CommonDigest.h>

#import "MSUtility+StringFormatting.h"

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityStringFormattingCategory;

static NSString *kMSTenantTokenString = @"tenantToken=";

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
  if(components == nil || components.count == 0) {
    return nil;
  }
  else {
    for(NSString *component in components) {
      
      // Component is app secret, return the component. Check for length > 0 as "foo;" will be parsed as 2 components.
      if(([component rangeOfString:kMSTenantTokenString].location == NSNotFound) && (component.length > 0)) {
        return component;
      }
    }
    
    // String does not contain an app secret.
    return nil;
  }
}

+ (NSString *)tenantIdFrom:(NSString *)string {
  NSArray *components = [string componentsSeparatedByString:@";"];
  if(components == nil || components.count == 0) {
    return nil;
  }
  else {
    for(NSString *component in components) {
      
      // Component is tenantId, return the component.
      
      if(([component rangeOfString:kMSTenantTokenString].location != NSNotFound) && (component.length > 0)) {
        return [component stringByReplacingOccurrencesOfString:kMSTenantTokenString withString:@""];
      }
    }
    
    // String does not contain a tokenId.
    return nil;
  }
}

@end
