/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSConstants.h"
#import <Foundation/Foundation.h>

@interface MSWrapperLogger : NSObject

+ (void)MSWrapperLog:(MSLogMessageProvider)message
                  tag:(NSString *)tag
                level:(MSLogLevel)level;;
@end
