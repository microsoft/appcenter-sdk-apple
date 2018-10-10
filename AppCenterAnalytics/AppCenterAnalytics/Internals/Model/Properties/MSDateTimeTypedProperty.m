#import "MSDateTimeTypedProperty.h"
#import "MSConstants+Internal.h"
#import "MSUtility+Date.h"

@implementation MSDateTimeTypedProperty

- (instancetype)init {
  if ((self = [super init])) {
    self.type = @"dateTime";
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    NSString *dateTimeString = [coder decodeObjectForKey:kMSTypedPropertyValue];
    _value = [MSUtility dateFromISO8601:dateTimeString];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  NSString *dateTimeString = [MSUtility dateToISO8601:self.value];
  [coder encodeObject:dateTimeString forKey:kMSTypedPropertyValue];
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  dict[kMSTypedPropertyValue] = self.value;
  return dict;
}

@end
