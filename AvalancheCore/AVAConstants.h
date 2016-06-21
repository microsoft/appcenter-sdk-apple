/*
 * The MIT License
 * Copyright (c) Microsoft Corporation.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
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

