#import "MSLocExtension.h"
#import "MSCSModelConstants.h"

@implementation MSLocExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict;
  if (self.tz) {
    dict = [NSMutableDictionary new];
    dict[kMSTimezone] = self.tz;
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {

  // All attributes are optional.
  return YES;
}
#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSLocExtension class]]) {
    return NO;
  }

  MSLocExtension *locExt = (MSLocExtension *)object;
  return (!self.tz && !locExt.tz) || [self.tz isEqualToString:locExt.tz];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _tz = [coder decodeObjectForKey:kMSTimezone];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.tz forKey:kMSTimezone];
}

@end
