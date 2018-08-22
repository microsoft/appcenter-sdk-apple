#import "MSWrapperLogger.h"
#import "MSLogger.h"

@implementation MSWrapperLogger

+ (void)MSWrapperLog:(MSLogMessageProvider)message
                 tag:(NSString *)tag
               level:(MSLogLevel)level {
  MSLog(level, tag, message);
}

@end
