/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMConstants.h"
#import <Foundation/Foundation.h>

#define SNMLog(_level, _message)                                                                                       \
  [SNMLogger logMessage:_message level:_level file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]
#define SNMLogAssert(format, ...)                                                                                      \
  SNMLog(SNMLogLevelAssert, (^{                                                                                        \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define SNMLogError(format, ...)                                                                                       \
  SNMLog(SNMLogLevelError, (^{                                                                                         \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define SNMLogWarning(format, ...)                                                                                     \
  SNMLog(SNMLogLevelWarning, (^{                                                                                       \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define SNMLogInfo(format, ...)                                                                                        \
  SNMLog(SNMLogLevelInfo, (^{                                                                                          \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define SNMLogDebug(format, ...)                                                                                       \
  SNMLog(SNMLogLevelDebug, (^{                                                                                         \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define SNMLogVerbose(format, ...)                                                                                     \
  SNMLog(SNMLogLevelVerbose, (^{                                                                                       \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))

@interface SNMLogger : NSObject

+ (SNMLogLevel)currentLogLevel;
+ (void)setCurrentLogLevel:(SNMLogLevel)currentLogLevel;
+ (void)setLogHandler:(SNMLogHandler)logHandler;
+ (void)logMessage:(SNMLogMessageProvider)messageProvider
             level:(SNMLogLevel)loglevel
              file:(const char *)file
          function:(const char *)function
              line:(uint)line;

@end
