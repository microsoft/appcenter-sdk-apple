// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACErrorDetails.h"
#import "MSACAbstractLogInternal.h"

static NSString *const kMSACCode = @"code";
static NSString *const kMSACMessage = @"message";

@implementation MSACErrorDetails

- (instancetype)initWithDictionary:(NSMutableDictionary *)dictionary {
  if ((self = [super init])) {
    if (dictionary[kMSACCode]) {
      self.code = (NSString *)dictionary[kMSACCode];
    }
    if (dictionary[kMSACMessage]) {
      self.message = (NSString *)dictionary[kMSACMessage];
    }
  }
  return self;
}

- (BOOL)isValid {
  return MSACLOG_VALIDATE_NOT_NIL(code) && MSACLOG_VALIDATE_NOT_NIL(message);
}

@end
