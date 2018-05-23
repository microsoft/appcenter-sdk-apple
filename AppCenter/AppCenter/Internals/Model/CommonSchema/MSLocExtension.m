#import "MSLocExtension.h"

static NSString *const kMSTimezone = @"timezone";

@implementation MSLocExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.timezone) {
    dict[kMSTimezone] = self.timezone;
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {
  return self.timezone;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSLocExtension class]]) {
    return NO;
  }

  MSLocExtension *locExt = (MSLocExtension *)object;
  return (!self.timezone && !locExt.timezone) || [self.timezone isEqualToString:locExt.timezone];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _timezone = [coder decodeObjectForKey:kMSTimezone];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.timezone forKey:kMSTimezone];
}

@end
