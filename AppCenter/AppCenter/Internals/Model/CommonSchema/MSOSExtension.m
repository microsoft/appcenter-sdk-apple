#import "MSCSModelConstants.h"
#import "MSOSExtension.h"

@implementation MSOSExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict;
  if (self.ver) {
    dict = [NSMutableDictionary new];
    dict[kMSOSVer] = self.ver;
  }
  if (self.name) {
    if (!dict) {
      dict = [NSMutableDictionary new];
    }
    dict[kMSOSName] = self.name;
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
  if (![(NSObject *)object isKindOfClass:[MSOSExtension class]]) {
    return NO;
  }
  MSOSExtension *osExt = (MSOSExtension *)object;
  return ((!self.ver && !osExt.ver) || [self.ver isEqualToString:osExt.ver]) &&
         ((!self.name && !osExt.name) || [self.name isEqualToString:osExt.name]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _ver = [coder decodeObjectForKey:kMSOSVer];
    _name = [coder decodeObjectForKey:kMSOSName];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.ver forKey:kMSOSVer];
  [coder encodeObject:self.name forKey:kMSOSName];
}

@end
