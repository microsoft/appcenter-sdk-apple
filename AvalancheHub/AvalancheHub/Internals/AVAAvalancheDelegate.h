/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "Model/AVALog.h"

@protocol AVAAvalancheDelegate <NSObject>

- (void)send:(id<AVALog>)log;

@end
