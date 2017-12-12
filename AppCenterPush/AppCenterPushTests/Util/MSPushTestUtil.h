#import <Foundation/Foundation.h>

@interface MSPushTestUtil : NSObject

+ (NSData *)convertPushTokenToNSData:(NSString *)token;

@end
