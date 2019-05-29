// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSLogger.h"
#import "MSWrapperLogger.h"

@implementation MSWrapperLogger

+ (void)MSWrapperLog:(MSLogMessageProvider)message tag:(NSString *)tag level:(MSLogLevel)level {
  MSLog(level, tag, message);
}

@end
