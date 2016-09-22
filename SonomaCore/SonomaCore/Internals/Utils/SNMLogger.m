#import "SNMLogger.h"

@implementation SNMLogger

static SNMLogLevel _currentLogLevel = SNMLogLevelAssert;
static SNMLogHandler currentLogHandler;
static BOOL _isUserDefinedLogLevel = NO;

SNMLogHandler defaultLogHandler =
    ^(SNMLogMessageProvider messageProvider, SNMLogLevel logLevel, const char *file, const char *function, uint line) {
      if (messageProvider) {
        if (_currentLogLevel < logLevel) {
          return;
        }
        NSLog((@"[Sonoma SDK] %s/%d %@"), function, line, messageProvider());
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
              file:(const char *)file
          function:(const char *)function
              line:(uint)line {
  if (currentLogHandler) {
    currentLogHandler(messageProvider, loglevel, file, function, line);
  }
}

+ (BOOL)isUserDefinedLogLevel {
  return _isUserDefinedLogLevel;
}

+ (void)setIsUserDefinedLogLevel:(BOOL)isUserDefinedLogLevel {
  _isUserDefinedLogLevel = isUserDefinedLogLevel;
}

@end
