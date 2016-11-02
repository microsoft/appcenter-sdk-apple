/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMWrapperLogger.h"
#import "SNMLogger.h"

@implementation SNMWrapperLogger

+ (void)SNMWrapperLog:(SNMLogMessageProvider)message
                  tag:(NSString *)tag
                level:(SNMLogLevel)level
{
    SNMLog(level, tag, message);
}

@end
