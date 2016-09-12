/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */
#ifndef SNM_Constants_h
#define SNM_Constants_h
#import <Foundation/Foundation.h>

/**
 *  Log Levels
 */
typedef NS_ENUM(NSUInteger, SNMLogLevel) {
  /**
   *  Logging is disabled
   */
  SNMLogLevelNone = 0,
  /**
   * Only critical errors will be logged
   */
  SNMLogLevelAssert = 1,
  /**
   *  Errors will be logged
   */
  SNMLogLevelError = 2,
  /**
   *  Errors and warnings will be logged
   */
  SNMLogLevelWarning = 3,
  /**
   *  Debug information will be logged
   */
  SNMLogLevelDebug = 4,
  /**
   *  Logging will be very chatty
   */
  SNMLogLevelVerbose = 5
};

typedef NSString * (^SNMLogMessageProvider)(void);
typedef void (^SNMLogHandler)(SNMLogMessageProvider messageProvider, SNMLogLevel logLevel, const char *file,
                              const char *function, uint line);

#endif
