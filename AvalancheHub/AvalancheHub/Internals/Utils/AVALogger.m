#import "AVALogger.h"

@implementation AVALogger

static AVALogLevel _currentLogLevel = AVALogLevelAssert;
static AVALogHandler currentLogHandler;

AVALogHandler defaultLogHandler =
    ^(AVALogMessageProvider messageProvider, AVALogLevel logLevel, const char *file, const char *function, uint line) {
      if (messageProvider) {
        if (_currentLogLevel < logLevel) {
          return;
        }
        NSLog((@"[Avalanche SDK] %s/%d %@"), function, line, messageProvider());
      }
    };

+ (void)initialize {
  currentLogHandler = defaultLogHandler;
}

+ (AVALogLevel)currentLogLevel {
  return _currentLogLevel;
}

+ (void)setCurrentLogLevel:(AVALogLevel)currentLogLevel {
  _currentLogLevel = currentLogLevel;
}

+ (void)setLogHandler:(AVALogHandler)logHandler {
  currentLogHandler = logHandler;
}

+ (void)logMessage:(AVALogMessageProvider)messageProvider
             level:(AVALogLevel)loglevel
              file:(const char *)file
          function:(const char *)function
              line:(uint)line {
  if (currentLogHandler) {
    currentLogHandler(messageProvider, loglevel, file, function, line);
  }
}

@end
