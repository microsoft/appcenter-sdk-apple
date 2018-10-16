#import "MSAbstractLogInternal.h"
#import "MSLogWithProperties.h"

static NSString *const kMSProperties = @"properties";

@implementation MSLogWithProperties

@synthesize properties = _properties;

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.properties && [self.properties count] != 0) {
    dict[kMSProperties] = self.properties;
  }
  return dict;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSLogWithProperties class]] || ![super isEqual:object]) {
    return NO;
  }
  MSLogWithProperties *log = (MSLogWithProperties *)object;
  return ((!self.properties && !log.properties) || [self.properties isEqualToDictionary:log.properties]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _properties = [coder decodeObjectForKey:kMSProperties];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.properties forKey:kMSProperties];
}

@end
