// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPushNotification.h"

@implementation MSPushNotification

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message customData:(NSDictionary<NSString *, NSString *> *)customData {
  if ((self = [super init]) != nil) {
    _title = title;
    _message = message;
    _customData = customData;
  }
  return self;
}

@end
