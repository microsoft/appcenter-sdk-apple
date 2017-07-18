#import "MSWrapperExceptionInternal.h"
#import "MSException.h"

@implementation MSWrapperException

static NSString* const kMSModelException = @"model_exception";
static NSString* const kMSExceptionData = @"exception_data";
static NSString* const KMSProcessId = @"process_id";

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.exception) {
    dict[kMSModelException] = self.modelException;
  }
  if (self.pid) {
    dict[KMSProcessId] = self.processId;
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
    self.modelException = [coder decodeObjectForKey:kMSModelException];
    self.exceptionData = [coder decodeObjectForKey:kMSExceptionData];
    self.processId = [coder decodeObjectForKey:KMSProcessId];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.modelException forKey:kMSModelException];
  [coder encodeObject:self.exceptionData forKey:kMSExceptionData];
  [coder encodeObject:self.processId forKey:KMSProcessId];
}

@end
