#import <Foundation/Foundation.h>

#import "MSConstants.h"

@interface MSWrapperLogger : NSObject

+ (void)MSWrapperLog:(MSLogMessageProvider)message tag:(NSString *)tag level:(MSLogLevel)level;
;
@end
