// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSLogContainer;
@class MSDevice;

NS_ASSUME_NONNULL_BEGIN

@interface MSTestUtil : NSObject

+ (MSLogContainer *)createLogContainerWithId:(NSString *)batchId device:(MSDevice *)device;

@end

NS_ASSUME_NONNULL_END
