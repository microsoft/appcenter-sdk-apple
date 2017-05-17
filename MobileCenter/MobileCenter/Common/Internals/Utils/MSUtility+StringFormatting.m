#import "MSUtility+StringFormatting.h"

#import <CommonCrypto/CommonDigest.h>

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityStringFormattingCategory;

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

@end
