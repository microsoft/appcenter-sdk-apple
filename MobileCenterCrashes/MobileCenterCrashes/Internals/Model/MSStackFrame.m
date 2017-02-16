#import "MSStackFrame.h"

static NSString *const kMSAddress = @"address";
static NSString *const kMSCode = @"code";
static NSString *const kMSClassName = @"class_name";
static NSString *const kMSMethodName = @"method_name";
static NSString *const kMSLineNumber = @"line_number";
static NSString *const kMSFileName = @"file_name";

@implementation MSStackFrame

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.address) {
    dict[kMSAddress] = self.address;
  }
  if (self.code) {
    dict[kMSCode] = self.code;
  }
  if (self.className) {
    dict[kMSClassName] = self.className;
  }
  if (self.methodName) {
    dict[kMSMethodName] = self.methodName;
  }
  if (self.lineNumber) {
    dict[kMSLineNumber] = self.lineNumber;
  }
  if (self.fileName) {
    dict[kMSFileName] = self.fileName;
  }
  return dict;
}

- (BOOL)isEqual:(MSStackFrame *)frame {
  if (!frame)
    return NO;

  return ((!self.address && !frame.address) || [self.address isEqualToString:frame.address]) &&
         ((!self.code && !frame.code) || [self.code isEqualToString:frame.code]) &&
         ((!self.className && !frame.className) || [self.className isEqualToString:frame.className]) &&
         ((!self.methodName && !frame.methodName) || [self.methodName isEqualToString:frame.methodName]) &&
         ((!self.lineNumber && !frame.lineNumber) || [self.lineNumber isEqual:frame.lineNumber]) &&
         ((!self.fileName && !frame.fileName) || [self.fileName isEqualToString:frame.fileName]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _address = [coder decodeObjectForKey:kMSAddress];
    _code = [coder decodeObjectForKey:kMSCode];
    _className = [coder decodeObjectForKey:kMSClassName];
    _methodName = [coder decodeObjectForKey:kMSMethodName];
    _lineNumber = [coder decodeObjectForKey:kMSLineNumber];
    _fileName = [coder decodeObjectForKey:kMSFileName];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.address forKey:kMSAddress];
  [coder encodeObject:self.code forKey:kMSCode];
  [coder encodeObject:self.className forKey:kMSClassName];
  [coder encodeObject:self.methodName forKey:kMSMethodName];
  [coder encodeObject:self.lineNumber forKey:kMSLineNumber];
  [coder encodeObject:self.fileName forKey:kMSFileName];
}

@end
