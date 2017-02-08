/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 *
 * OpenAPI spec version: 1.0.0-preview20160708
 */

#import "MSAbstractLog.h"

@import Foundation;

@interface MSLogWithProperties : MSAbstractLog

/* Additional key/value pair parameters.  [optional]
 */
@property(nonatomic) NSDictionary<NSString *, NSString *> *properties;

@end
