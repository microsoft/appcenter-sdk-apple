#import <Foundation/Foundation.h>

@interface MSPushTestUtil : NSObject

+ (NSData*)convertDeviceTokenToNSData:(NSString*)token;

@end
