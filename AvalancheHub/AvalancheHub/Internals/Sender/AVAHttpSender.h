/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AVASender.h"
#import "AVAChannelDelegate.h"

@interface AVAHttpSender : NSObject<AVASender>

@property (nonatomic, weak) id<AVAChannelDelegate> delegate;

@end
