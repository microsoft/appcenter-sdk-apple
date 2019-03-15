// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSLog.h"
#import "MSLogConversion.h"

@protocol MSMockLogWithConversion <MSLog, MSLogConversion, NSObject>
@end
