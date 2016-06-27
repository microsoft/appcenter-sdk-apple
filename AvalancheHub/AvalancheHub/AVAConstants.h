/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */
#ifndef AVA_Constants_h
#define AVA_Constants_h

/**
 *  Log Levels
 */
typedef NS_ENUM(NSUInteger, AVALogLevel) {
  /**
   *  Logging is disabled
   */
  AVALogLevelNone = 0,
  /**
   *  Only errors will be logged
   */
  AVALogLevelError = 1,
  /**
   *  Errors and warnings will be logged
   */
  AVALogLevelWarning = 2,
  /**
   *  Debug information will be logged
   */
  AVALogLevelDebug = 3,
  /**
   *  Logging will be very chatty
   */
  AVALogLevelVerbose = 4
};

typedef NSString *(^AVALogMessageProvider)(void);
typedef void (^AVALogHandler)(AVALogMessageProvider messageProvider, AVALogLevel logLevel, const char *file, const char *function, uint line);

#endif

