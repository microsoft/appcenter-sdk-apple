#import "MSNetExtension.h"
#import "MSCSModelConstants.h"

@implementation MSNetExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict;
  if (self.provider) {
    dict = [NSMutableDictionary new];
    dict[kMSNetProvider] = self.provider;
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
  if (![(NSObject *)object isKindOfClass:[MSNetExtension class]]) {
    return NO;
  }
  MSNetExtension *netExt = (MSNetExtension *)object;
  return ((!self.provider && !netExt.provider) || [self.provider isEqualToString:netExt.provider]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _provider = [coder decodeObjectForKey:kMSNetProvider];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.provider forKey:kMSNetProvider];
}

@end
