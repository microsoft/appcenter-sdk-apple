// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#if __has_include("MSLogWithProperties.h")
#import "MSLogWithProperties.h"
#else
#import <AppCenter/MSLogWithProperties.h>
#endif

@interface MSLogWithNameAndProperties : MSLogWithProperties

/**
 * Name of the event.
 */
@property(nonatomic, copy) NSString *name;

@end
