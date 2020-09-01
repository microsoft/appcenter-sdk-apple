// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHandledErrorLog.h"
#import "MSException.h"

static NSString *const kMSTypeError = @"handledError";
static NSString *const kMSId = @"id";
static NSString *const kMSException = @"exception";

@implementation MSHandledErrorLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypeError;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.errorId) {
    dict[kMSId] = self.errorId;
  }
  if (self.exception) {
    dict[kMSException] = [self.exception serializeToDictionary];
  }
  return dict;
}

- (BOOL)isValid {
  return [super isValid] && MSLOG_VALIDATE_NOT_NIL(errorId) && MSLOG_VALIDATE_NOT_NIL(exception);
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSHandledErrorLog class]] || ![super isEqual:object]) {
    return NO;
  }
  MSHandledErrorLog *errorLog = (MSHandledErrorLog *)object;
  return ((!self.errorId && !errorLog.errorId) || [self.errorId isEqual:errorLog.errorId]) &&
         ((!self.exception && !errorLog.exception) || [self.exception isEqual:errorLog.exception]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _errorId = [coder decodeObjectForKey:kMSId];
    _exception = [coder decodeObjectForKey:kMSException];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.errorId forKey:kMSId];
  [coder encodeObject:self.exception forKey:kMSException];
}

@end
