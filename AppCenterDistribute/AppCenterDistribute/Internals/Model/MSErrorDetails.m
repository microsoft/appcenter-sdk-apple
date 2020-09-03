// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSErrorDetails.h"
#import "MSAbstractLogInternal.h"

static NSString *const kMSCode = @"code";
static NSString *const kMSMessage = @"message";

@implementation MSErrorDetails

- (instancetype)initWithDictionary:(NSMutableDictionary *)dictionary {
  if ((self = [super init])) {
    if (dictionary[kMSCode]) {
      self.code = (NSString *)dictionary[kMSCode];
    }
    if (dictionary[kMSMessage]) {
      self.message = (NSString *)dictionary[kMSMessage];
    }
  }
  return self;
}

- (BOOL)isValid {
  return MSLOG_VALIDATE_NOT_NIL(code) && MSLOG_VALIDATE_NOT_NIL(message);
}

@end
