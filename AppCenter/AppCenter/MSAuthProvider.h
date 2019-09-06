// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAuthProviderDelegate.h"

@interface MSAuthProvider : NSObject

@property(nonatomic, readonly, weak) id<MSAuthProviderDelegate> delegate;

@end
