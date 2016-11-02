/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMConstants.h"
#import <Foundation/Foundation.h>

@interface SNMWrapperLogger : NSObject

+ (void)SNMWrapperLog:(SNMLogMessageProvider)message
                  tag:(NSString *)tag
                level:(SNMLogLevel)level;
@end
