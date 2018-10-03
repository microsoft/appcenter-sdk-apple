#import "MSLogger.h"

FOUNDATION_EXPORT MSLogHandler const msDefaultLogHandler;

@interface MSLogger ()

+ (BOOL)isUserDefinedLogLevel;

/*
 * For testing only.
 */
+ (void)setIsUserDefinedLogLevel:(BOOL)isUserDefinedLogLevel;

+ (MSLogLevel)currentLogLevel;

+ (void)setCurrentLogLevel:(MSLogLevel)currentLogLevel;

+ (void)setLogHandler:(MSLogHandler)logHandler;

@end
