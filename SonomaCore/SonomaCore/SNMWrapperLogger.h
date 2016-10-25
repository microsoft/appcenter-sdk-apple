/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMLogger.h"

@interface SNMWrapperLogger : NSObject

+ (void)SNMWrapperLog:(SNMLogMessageProvider)message
                  tag:(NSString *)tag
                level:(SNMLogLevel)level;
@end
