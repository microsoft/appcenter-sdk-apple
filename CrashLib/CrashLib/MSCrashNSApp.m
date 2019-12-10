// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSCrashNSApp.h"

@implementation MSCrashNSApp

- (NSString *)category {
    return @"Exceptions";
}

- (NSString *)title {
    return @"Throw Objective-C exception avoiding send event";
}

- (NSString *)desc {
    return @""
    "Throw an uncaught Objective-C exception avoiding send event. "
    "It's possible to generate a better crash report here compared to the C++ Exception case "
    "because NSUncaughtExceptionHandler can be used, which isn't available for C++ extensions.";
}

- (void)crash {
    [self performSelector:@selector(delayedException) withObject:nil afterDelay:0.1];
}

- (void)delayedException {
    @throw [NSException exceptionWithName:NSGenericException reason:@"An uncaught exception! SCREAM."
                                 userInfo:@{NSLocalizedDescriptionKey: @"I'm in your program, catching your exceptions!"}];
}

@end
