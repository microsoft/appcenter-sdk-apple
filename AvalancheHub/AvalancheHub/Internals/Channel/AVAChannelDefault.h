/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AVAChannel.h"
#import "AVAChannelDelegate.h"

/**
 A channel which manages a queue of log items. All items will be immediately passed to
 the persistence layer in order to make the queue crash safe. Once a maximum number of 
 items have been enqueued or the internal timer finished running, events will be 
 forwarded to the sender. Furthermore, its responsibility is to tell the persitence layer
 what to do with a pending batch based on the status code returned by the sender
 */
@interface AVAChannelDefault : NSObject <AVAChannel, AVAChannelDelegate>

@end
