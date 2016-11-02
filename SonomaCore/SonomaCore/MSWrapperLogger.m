/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSWrapperLogger.h"
#import "MSLogger.h"

@implementation MSWrapperLogger

+ (void)SNMWrapperLog:(SNMLogMessageProvider)message
                  tag:(NSString *)tag
                level:(SNMLogLevel)level
{
    SNMLog(level, tag, message);
}

@end
