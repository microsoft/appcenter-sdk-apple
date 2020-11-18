// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#if __has_include(<AppCenter/MSACLogWithProperties.h>)
#import <AppCenter/MSACLogWithProperties.h>
#else
#import "MSACLogWithProperties.h"
#endif

NS_SWIFT_NAME(LogWithNameAndProperties)
@interface MSACLogWithNameAndProperties : MSACLogWithProperties

/**
 * Name of the event.
 */
@property(nonatomic, copy) NSString *name;

@end
