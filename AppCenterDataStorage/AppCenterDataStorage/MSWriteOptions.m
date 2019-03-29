// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSWriteOptions.h"

@implementation MSWriteOptions

- (instancetype)init {
    self = [super init];
    return self;
}

- (instancetype)initWithTimeToLive:(NSInteger)timeToLive {
    self = [super initWithDeviceTimeToLive:timeToLive];
    return self;
}

@end
