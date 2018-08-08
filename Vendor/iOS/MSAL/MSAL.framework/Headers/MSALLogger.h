//------------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

/*! Levels of logging. Defines the priority of the logged message */
typedef NS_ENUM(NSInteger, MSALLogLevel)
{
    MSALLogLevelNothing,
    MSALLogLevelError,
    MSALLogLevelWarning,
    MSALLogLevelInfo,
    MSALLogLevelVerbose,
    MSALLogLevelLast = MSALLogLevelVerbose,
};


/*!
    The LogCallback block for the MSAL logger
 
    @param  level           The level of the log message
    @param  message         The message being logged
    @param  containsPII     If the message might contain Personally Identifiable Information (PII)
                            this will be true. Log messages possibly containing PII will not be
                            sent to the callback unless PIllLoggingEnabled is set to YES on the
                            logger.

 */
typedef void (^MSALLogCallback)(MSALLogLevel level, NSString *message, BOOL containsPII);


@interface MSALLogger : NSObject

+ (MSALLogger *)sharedLogger;

/*!
    The minimum log level for messages to be passed onto the log callback.
 */
@property (readwrite) MSALLogLevel level;

/*!
    MSAL provides logging callbacks that assist in diagnostics. There is a boolean value in the logging callback that indicates whether the message contains user information. If PiiLoggingEnabled is set to NO, the callback will not be triggered for log messages that contain any user information. By default the library will not return any messages with user information in them.
 */
@property (readwrite) BOOL PiiLoggingEnabled;

/*!
    Sets the callback block to send MSAL log messages to.
 
    NOTE: Once this is set this can not be unset, and it should be set early in
          the program's execution.
 */
- (void)setCallback:(MSALLogCallback)callback;

@end
