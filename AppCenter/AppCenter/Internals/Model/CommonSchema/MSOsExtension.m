#import "MSOsExtension.h"

static NSString *const kMSOsVer = @"ver";
static NSString *const kMSOsName = @"name";

@implementation MSOsExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.ver) {
    dict[kMSOsVer] = self.ver;
  }
  if (self.name) {
    dict[kMSOsName] = self.name;
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {
  return self.ver && self.name;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSOsExtension class]]) {
    return NO;
  }
  MSOsExtension *osExt = (MSOsExtension *)object;
  return ((!self.ver && !osExt.ver) || [self.ver isEqualToString:osExt.ver]) &&
         ((!self.name && !osExt.name) || [self.name isEqualToString:osExt.name]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _ver = [coder decodeObjectForKey:kMSOsVer];
    _name = [coder decodeObjectForKey:kMSOsName];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.ver forKey:kMSOsVer];
  [coder encodeObject:self.name forKey:kMSOsName];
}

@end
