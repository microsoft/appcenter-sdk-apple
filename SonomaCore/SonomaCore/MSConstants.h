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
   *  Logging will be very chatty
   */
      SNMLogLevelVerbose = 2,

  /**
   *  Debug information will be logged
   */
      SNMLogLevelDebug = 3,

  /**
   *  Information will be logged
   */
      SNMLogLevelInfo = 4,

  /**
   *  Errors and warnings will be logged
   */
      SNMLogLevelWarning = 5,

  /**
   *  Errors will be logged
   */
      SNMLogLevelError = 6,

  /**
   * Only critical errors will be logged
   */
      SNMLogLevelAssert = 7,

  /**
   *  Logging is disabled
   */
      SNMLogLevelNone = 99,
};

typedef NSString *(^SNMLogMessageProvider)(void);
typedef void (^SNMLogHandler)(SNMLogMessageProvider messageProvider, SNMLogLevel logLevel, NSString *tag, const char *file,
                              const char *function, uint line);

#endif
