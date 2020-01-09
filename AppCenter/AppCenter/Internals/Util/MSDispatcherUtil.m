// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDispatcherUtil.h"
#import "MSAppCenterInternal.h"

@implementation MSDispatcherUtil

+ (void)performBlockOnMainThread:(void (^)(void))block {

#if TARGET_OS_OSX
  [self performSelectorOnMainThread:@selector(runBlock:) withObject:block waitUntilDone:NO];
#else
  if ([NSThread isMainThread]) {
    block();
  } else {
    dispatch_async(dispatch_get_main_queue(), block);
  }
#endif
}

+ (void)runBlock:(void (^)(void))block {
  block();
}

@end
