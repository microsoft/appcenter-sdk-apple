// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSWriteOptions.h"

@implementation MSWriteOptions

- (instancetype)init {
    self = [super init];
    return self;
}

- (instancetype)initWithTtl:(NSInteger)ttl {
    self = [super initWithDeviceTimeToLive:ttl];
    return self;
}

@end
