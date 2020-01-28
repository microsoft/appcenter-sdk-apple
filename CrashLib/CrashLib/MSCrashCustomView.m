// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSCrashCustomView.h"

@implementation MSCrashCustomView

- (NSString *)category {
  return @"Exceptions";
}

- (NSString *)title {
  return @"Throw Objective-C exception during dwawing custom view";
}

- (NSString *)desc {
  return @"Throw an uncaught Objective-C exception during dwawing custom view.";
}

- (void)crash {
  // TODO
}

@end
