//
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
//

#import "MSServiceAbstract.h"
#import "MSServiceInternal.h"

@interface MSMockService : MSServiceAbstract <MSServiceInternal>

@property BOOL started;

+ (void)resetSharedInstance;

@end
