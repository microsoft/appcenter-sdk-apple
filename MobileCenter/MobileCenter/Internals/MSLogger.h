/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSConstants.h"
#import <Foundation/Foundation.h>

#define MSLog(_level, _tag, _message)                                                                                 \
  [MSLogger logMessage:_message level:_level tag:_tag file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]
#define MSLogAssert(tag, format, ...)                                                                                 \
  MSLog(MSLogLevelAssert, tag, (^{                                                                                   \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define MSLogError(tag, format, ...)                                                                                  \
  MSLog(MSLogLevelError, tag, (^{                                                                                    \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define MSLogWarning(tag, format, ...)                                                                                \
  MSLog(MSLogLevelWarning, tag, (^{                                                                                  \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define MSLogInfo(tag, format, ...)                                                                                   \
  MSLog(MSLogLevelInfo, tag, (^{                                                                                     \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define MSLogDebug(tag, format, ...)                                                                                  \
  MSLog(MSLogLevelDebug, tag, (^{                                                                                    \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define MSLogVerbose(tag, format, ...)                                                                                \
  MSLog(MSLogLevelVerbose, tag, (^{                                                                                  \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))

FOUNDATION_EXPORT MSLogHandler const defaultLogHandler;

@interface MSLogger : NSObject

+ (void)logMessage:(MSLogMessageProvider)messageProvider
             level:(MSLogLevel)loglevel
               tag:(NSString *)tag
              file:(const char *)file
          function:(const char *)function
              line:(uint)line;

+ (BOOL)isUserDefinedLogLevel;

/*
 * For testing only.
 */
+ (void)setIsUserDefinedLogLevel:(BOOL)isUserDefinedLogLevel;

+ (MSLogLevel)currentLogLevel;
+ (void)setCurrentLogLevel:(MSLogLevel)currentLogLevel;
+ (void)setLogHandler:(MSLogHandler)logHandler;


@end
