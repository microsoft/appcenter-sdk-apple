/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "Model/AVALog.h"
#import "Utils/AVAConstants+Internal.h"
#import <Foundation/Foundation.h>

@protocol AVAAvalancheDelegate <NSObject>

- (void)feature:(id)feature
   didCreateLog:(id<AVALog>)log
   withPriority:(AVAPriority)priority;

@end
