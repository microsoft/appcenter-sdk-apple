// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@import Cocoa;
@import AppCenterCrashes;

@interface AppCenterApplication : NSApplication
@end

@implementation AppCenterApplication

- (void)reportException:(NSException *)exception {
  [MSACCrashes applicationDidReportException:exception];
  [super reportException:exception];
}

- (void)sendEvent:(NSEvent *)theEvent {
  @try {
    [super sendEvent:theEvent];
  } @catch (NSException *exception) {
    [self reportException:exception];
  }
}

@end
