/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAConstants.h"
#import <Foundation/Foundation.h>

#define AVALog(_level, _message)                                                                                       \
  [AVALogger logMessage:_message level:_level file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]
#define AVALogError(format, ...)                                                                                       \
  AVALog(AVALogLevelError, (^{                                                                                         \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define AVALogWarning(format, ...)                                                                                     \
  AVALog(AVALogLevelWarning, (^{                                                                                       \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define AVALogDebug(format, ...)                                                                                       \
  AVALog(AVALogLevelDebug, (^{                                                                                         \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))
#define AVALogVerbose(format, ...)                                                                                     \
  AVALog(AVALogLevelVerbose, (^{                                                                                       \
           return [NSString stringWithFormat:(format), ##__VA_ARGS__];                                                 \
         }))

@interface AVALogger : NSObject

+ (AVALogLevel)currentLogLevel;
+ (void)setCurrentLogLevel:(AVALogLevel)currentLogLevel;
+ (void)setLogHandler:(AVALogHandler)logHandler;
+ (void)logMessage:(AVALogMessageProvider)messageProvider
             level:(AVALogLevel)loglevel
              file:(const char *)file
          function:(const char *)function
              line:(uint)line;

@end
