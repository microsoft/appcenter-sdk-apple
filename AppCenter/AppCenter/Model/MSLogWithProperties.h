// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#if __has_include("MSAbstractLog.h")
#import "MSAbstractLog.h"
#else
#import <AppCenter/MSAbstractLog.h>
#endif

@interface MSLogWithProperties : MSAbstractLog

/**
 * Additional key/value pair parameters. [optional]
 */
@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *properties;

@end
