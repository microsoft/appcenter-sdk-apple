#import "MSPushTestUtil.h"

@implementation MSPushTestUtil

+ (NSData *)convertPushTokenToNSData:(NSString *)token {
  NSMutableData *data = [[NSMutableData alloc] init];
  unsigned char whole_byte;
  char byte_chars[3] = {'\0', '\0', '\0'};
  for (NSUInteger i = 0; i < ([token length] / 2); i++) {
    byte_chars[0] = (char)[token characterAtIndex:i * 2];
    byte_chars[1] = (char)[token characterAtIndex:i * 2 + 1];
    whole_byte = (unsigned char)strtol(byte_chars, NULL, 16);
    [data appendBytes:&whole_byte length:1];
  }
  return data;
}

@end
