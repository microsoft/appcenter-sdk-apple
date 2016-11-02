/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSConstants.h"
#import <Foundation/Foundation.h>

@interface MSWrapperLogger : NSObject

+ (void)SNMWrapperLog:(SNMLogMessageProvider)message
                  tag:(NSString *)tag
                level:(SNMLogLevel)level;
@end
