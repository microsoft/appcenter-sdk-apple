#import "MSLoggerInternal.h"

@implementation MSLogger

static MSLogLevel _currentLogLevel = MSLogLevelAssert;
static MSLogHandler currentLogHandler;
static BOOL _isUserDefinedLogLevel = NO;

MSLogHandler const msDefaultLogHandler = ^(MSLogMessageProvider messageProvider, MSLogLevel logLevel, NSString *tag,
                                           __attribute__((unused)) const char *file, const char *function, uint line) {
  if (messageProvider) {
    if (_currentLogLevel > logLevel) {
      return;
    }
    NSString *level;
    switch (logLevel) {
    case MSLogLevelVerbose:
      level = @"VERBOSE";
      break;
    case MSLogLevelDebug:
      level = @"DEBUG";
      break;
    case MSLogLevelInfo:
      level = @"INFO";
      break;
    case MSLogLevelWarning:
      level = @"WARNING";
      break;
    case MSLogLevelError:
      level = @"ERROR";
      break;
    case MSLogLevelAssert:
      level = @"ASSERT";
      break;
    case MSLogLevelNone:
      return;
    }
    NSLog(@"[%@] %@: %@/%d %@", tag, level, [NSString stringWithCString:function encoding:NSUTF8StringEncoding], line, messageProvider());
  }
};

+ (void)initialize {
  currentLogHandler = msDefaultLogHandler;
}

+ (MSLogLevel)currentLogLevel {
  @synchronized(self) {
    return _currentLogLevel;
  }
}

+ (void)setCurrentLogLevel:(MSLogLevel)currentLogLevel {
  @synchronized(self) {
    _isUserDefinedLogLevel = YES;
    _currentLogLevel = currentLogLevel;
  }
}

+ (void)setLogHandler:(MSLogHandler)logHandler {
  @synchronized(self) {
    _isUserDefinedLogLevel = YES;
    currentLogHandler = logHandler;
  }
}

+ (void)logMessage:(MSLogMessageProvider)messageProvider
             level:(MSLogLevel)loglevel
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
