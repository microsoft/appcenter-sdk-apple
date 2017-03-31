#import "MSCustomProperties.h"
#import "MSCustomPropertiesPrivate.h"

@implementation MSCustomProperties

- (MSCustomProperties *)setString:(NSString *)value forKey:(NSString *)key {
  return self;
}

- (MSCustomProperties *)setNumber:(NSNumber *)value forKey:(NSString *)key {
  return self;
}

- (MSCustomProperties *)setBool:(BOOL)value forKey:(NSString *)key {
  return self;
}

- (MSCustomProperties *)setDate:(NSDate *)value forKey:(NSString *)key {
  return self;
}

- (MSCustomProperties *)clearPropertyForKey:(NSString *)key {
  return self;
}

@end
