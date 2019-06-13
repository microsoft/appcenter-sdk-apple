// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSServiceAbstractInternal.h"

@interface MSMockService : MSServiceAbstract <MSServiceInternal>

+ (void)resetSharedInstance;

@end
