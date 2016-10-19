/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMConstants.h"
#import <Foundation/Foundation.h>

#define SNMLog(_level, _tag, _message)                                                                                 \
  [SNMLogger logMessage:_message level:_level tag:_tag file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]
#define SNMLogAssert(tag, format, ...)                                                                                 \
  SNMLog(SNMLogLevelAssert, tag, (^{                                                                                   \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define SNMLogError(tag, format, ...)                                                                                  \
  SNMLog(SNMLogLevelError, tag, (^{                                                                                    \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define SNMLogWarning(tag, format, ...)                                                                                \
  SNMLog(SNMLogLevelWarning, tag, (^{                                                                                  \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define SNMLogInfo(tag, format, ...)                                                                                   \
  SNMLog(SNMLogLevelInfo, tag, (^{                                                                                     \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define SNMLogDebug(tag, format, ...)                                                                                  \
  SNMLog(SNMLogLevelDebug, tag, (^{                                                                                    \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define SNMLogVerbose(tag, format, ...)                                                                                \
  SNMLog(SNMLogLevelVerbose, tag, (^{                                                                                  \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))

@interface SNMLogger : NSObject

+ (SNMLogLevel)currentLogLevel;
+ (void)setCurrentLogLevel:(SNMLogLevel)currentLogLevel;
+ (void)setLogHandler:(SNMLogHandler)logHandler;
+ (void)logMessage:(SNMLogMessageProvider)messageProvider
             level:(SNMLogLevel)loglevel
               tag:(NSString *)tag
              file:(const char *)file
          function:(const char *)function
              line:(uint)line;

@end
