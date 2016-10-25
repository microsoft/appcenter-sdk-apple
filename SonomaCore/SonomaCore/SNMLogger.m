#import "SNMLogger.h"
#import "SNMWrapperLogger.h"

@implementation SNMLogger

static SNMLogLevel _currentLogLevel = SNMLogLevelAssert;
static SNMLogHandler currentLogHandler;
static BOOL _isUserDefinedLogLevel = NO;

SNMLogHandler defaultLogHandler =
    ^(SNMLogMessageProvider messageProvider, SNMLogLevel logLevel, NSString *tag, const char *file, const char *function, uint line) {
      if (messageProvider) {
        if (_currentLogLevel > logLevel) {
          return;
        }

        NSString *level;
        switch (logLevel) {
        case SNMLogLevelVerbose:
          level = @"VERBOSE";
          break;
        case SNMLogLevelDebug:
          level = @"DEBUG";
          break;
        case SNMLogLevelInfo:
          level = @"INFO";
          break;
        case SNMLogLevelWarning:
          level = @"WARNING";
          break;
        case SNMLogLevelError:
          level = @"ERROR";
          break;
        case SNMLogLevelAssert:
          level = @"ASSERT";
          break;
        default:
          // Ignore if log level is not valid. Will never fall to this default case.
          return;
        }
        NSLog((@"[%@] %@: %s/%d %@"), tag, level, function, line, messageProvider());
      }
    };

+ (void)initialize {
  currentLogHandler = defaultLogHandler;
}

+ (SNMLogLevel)currentLogLevel {
  return _currentLogLevel;
}

+ (void)setCurrentLogLevel:(SNMLogLevel)currentLogLevel {
  _isUserDefinedLogLevel = YES;
  _currentLogLevel = currentLogLevel;
}

+ (void)setLogHandler:(SNMLogHandler)logHandler {
  _isUserDefinedLogLevel = YES;
  currentLogHandler = logHandler;
}

+ (void)logMessage:(SNMLogMessageProvider)messageProvider
             level:(SNMLogLevel)loglevel
               tag:(NSString *)tag
              file:(const char *)file
          function:(const char *)function
              line:(uint)line {
  if (currentLogHandler) {
    currentLogHandler(messageProvider, loglevel, tag, file, function, line);
  }
}

+ (BOOL)isUserDefinedLogLevel {
  return _isUserDefinedLogLevel;
}

+ (void)setIsUserDefinedLogLevel:(BOOL)isUserDefinedLogLevel {
  _isUserDefinedLogLevel = isUserDefinedLogLevel;
}

@end
