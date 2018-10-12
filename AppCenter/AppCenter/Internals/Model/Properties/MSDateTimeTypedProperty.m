#import "MSDateTimeTypedProperty.h"
#import "MSUtility+Date.h"

static NSString *const kMSDateTimeTypedPropertyType = @"dateTime";

@implementation MSDateTimeTypedProperty

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSDateTimeTypedPropertyType;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _value = [coder decodeObjectForKey:kMSTypedPropertyValue];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.value forKey:kMSTypedPropertyValue];
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  dict[kMSTypedPropertyValue] = [MSUtility dateToISO8601:self.value];
  return dict;
}

@end
