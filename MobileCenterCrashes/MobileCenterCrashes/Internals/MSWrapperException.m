#import "MSWrapperExceptionInternal.h"
#import "MSException.h"

@implementation MSWrapperException

static NSString *const kMSModelException = @"model_exception";
static NSString *const kMSExceptionData = @"exception_data";
static NSString *const kMSTimeStamp = @"timestamp";

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.exception) {
    dict[kMSModelException] = self.exception;
  }
  if (self.timestamp) {
    dict[kMSTimeStamp] = self.timestamp;
  }
  if (self.exceptionData) {
    dict[kMSExceptionData] = self.exceptionData;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    self.exception = [coder decodeObjectForKey:kMSModelException];
    self.exceptionData = [coder decodeObjectForKey:kMSExceptionData];
    self.timestamp = [coder decodeObjectForKey:kMSTimeStamp];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.exception forKey:kMSModelException];
  [coder encodeObject:self.exceptionData forKey:kMSExceptionData];
  [coder encodeObject:self.timestamp forKey:kMSTimeStamp];
}

@end
