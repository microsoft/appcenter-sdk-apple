#import "MSException.h"
#import "MSStackFrame.h"

static NSString *const kMSExceptionType = @"type";
static NSString *const kMSMessage = @"message";
static NSString *const kMSFrames = @"frames";
static NSString *const kMSStackTrace = @"stackTrace";
static NSString *const kMSInnerExceptions = @"innerExceptions";
static NSString *const kMSWrapperSDKName = @"wrapperSdkName";

@implementation MSException

- (NSMutableDictionary *)serializeToDictionary {

  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.type) {
    dict[kMSExceptionType] = self.type;
  }
  if (self.message) {
    dict[kMSMessage] = self.message;
  }
  if (self.stackTrace) {
    dict[kMSStackTrace] = self.stackTrace;
  }
  if (self.wrapperSdkName) {
    dict[kMSWrapperSDKName] = self.wrapperSdkName;
  }
  if (self.frames) {
    NSMutableArray *framesArray = [NSMutableArray array];
    for (MSStackFrame *frame in self.frames) {
      [framesArray addObject:[frame serializeToDictionary]];
    }
    dict[kMSFrames] = framesArray;
  }
  if (self.innerExceptions) {
    NSMutableArray *exceptionsArray = [NSMutableArray array];
    for (MSException *exception in self.innerExceptions) {
      [exceptionsArray addObject:[exception serializeToDictionary]];
    }
    dict[kMSInnerExceptions] = exceptionsArray;
  }

  return dict;
}

- (BOOL)isValid {
  return self.type && [self.frames count] > 0;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSException class]]) {
    return NO;
  }
  MSException *exception = (MSException *)object;
  return ((!self.type && !exception.type) || [self.type isEqualToString:exception.type]) &&
         ((!self.wrapperSdkName && !exception.wrapperSdkName) || [self.wrapperSdkName isEqualToString:exception.wrapperSdkName]) &&
         ((!self.message && !exception.message) || [self.message isEqualToString:exception.message]) &&
         ((!self.frames && !exception.frames) || [self.frames isEqualToArray:exception.frames]) &&
         ((!self.innerExceptions && !exception.innerExceptions) || [self.innerExceptions isEqualToArray:exception.innerExceptions]) &&
         ((!self.stackTrace && !exception.stackTrace) || [self.stackTrace isEqualToString:exception.stackTrace]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = [coder decodeObjectForKey:kMSExceptionType];
    _message = [coder decodeObjectForKey:kMSMessage];
    _stackTrace = [coder decodeObjectForKey:kMSStackTrace];
    _frames = [coder decodeObjectForKey:kMSFrames];
    _innerExceptions = [coder decodeObjectForKey:kMSInnerExceptions];
    _wrapperSdkName = [coder decodeObjectForKey:kMSWrapperSDKName];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.type forKey:kMSExceptionType];
  [coder encodeObject:self.message forKey:kMSMessage];
  [coder encodeObject:self.stackTrace forKey:kMSStackTrace];
  [coder encodeObject:self.frames forKey:kMSFrames];
  [coder encodeObject:self.innerExceptions forKey:kMSInnerExceptions];
  [coder encodeObject:self.wrapperSdkName forKey:kMSWrapperSDKName];
}

@end
