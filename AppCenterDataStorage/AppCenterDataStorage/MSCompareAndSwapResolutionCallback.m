//
//  MSCompareAndSwapResolutionCallback.m
//  AppCenterDataStorageIOS
//
//  Created by Mehrdad Mozafari on 2/15/19.
//  Copyright © 2019 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSCompareAndSwapResolutionCallback.h"
#import "MSConflictResolutionDelegate.h"

@implementation MSCompareAndSwapResolutionCallback


+ (instancetype)compareAndSwapPolicyWithDocument
{
  return nil;
}


// Return the "compare and swap" policy
// The write operation will only be accepted by the server, if the local document
// that was previously read is still currently the one the server knows
// about (i.e. if its etag matches)
+ (instancetype)compareAndSwapPolicyWithEtag:(NSString *)etag
{
  (void)etag;
  return nil;
}

// Same as above, but provide a callback to resolve conflicts in case
// the server rejects an operation
+ (instancetype)conflictResolutionPolicyWithEtag:(NSString *)etag delegate:(id<MSConflictResolutionDelegate>)delgate
{
  (void)etag;
  (void)delgate;
  return nil;
}

@end
