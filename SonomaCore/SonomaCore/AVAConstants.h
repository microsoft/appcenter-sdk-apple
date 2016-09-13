/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */
#ifndef AVA_Constants_h
#define AVA_Constants_h
#import <Foundation/Foundation.h>

/**
 *  Log Levels
 */
typedef NS_ENUM(NSUInteger, AVALogLevel) {
  /**
   *  Logging is disabled
   */
  AVALogLevelNone = 0,
  /**
   * Only critical errors will be logged
   */
  AVALogLevelAssert = 1,
  /**
   *  Errors will be logged
   */
  AVALogLevelError = 2,
  /**
   *  Errors and warnings will be logged
   */
  AVALogLevelWarning = 3,
  /**
   *  Debug information will be logged
   */
  AVALogLevelDebug = 4,
  /**
   *  Logging will be very chatty
   */
  AVALogLevelVerbose = 5
};

typedef NSString * (^AVALogMessageProvider)(void);
typedef void (^AVALogHandler)(AVALogMessageProvider messageProvider, AVALogLevel logLevel, const char *file,
                              const char *function, uint line);

#endif
