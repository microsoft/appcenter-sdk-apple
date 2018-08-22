#import "MSException.h"
#import "MSWrapperExceptionInternal.h"

@implementation MSWrapperException

static NSString *const kMSModelException = @"modelException";
static NSString *const kMSExceptionData = @"exceptionData";
static NSString *const KMSProcessId = @"processId";

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.modelException) {
    dict[kMSModelException] = [self.modelException serializeToDictionary];
  }
  if (self.processId) {
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
