#import "MSCustomProperties.h"
#import "MSCustomPropertiesPrivate.h"
#import "MSMobileCenterInternal.h"
#import "MSStartServiceLog.h"

static NSString *const kKeyPattern = @"^[a-zA-Z][a-zA-Z0-9]*$";
static NSString *const kValueNullErrorMessage = @"Custom property value cannot be null, did you mean to call clear?";

@implementation MSCustomProperties

@synthesize properties = _properties;

- (instancetype)init {
  if ((self = [super init])) {
    _properties = [NSMutableDictionary new];
  }
  return self;
}

- (MSCustomProperties *)setString:(NSString *)value forKey:(NSString *)key {
  if ([self isValidKey:key]) {
    if (value) {
      [self.properties setObject:value forKey:key];
    } else {
      MSLogError([MSMobileCenter logTag], kValueNullErrorMessage);
    }
  }
  return self;
}

- (MSCustomProperties *)setNumber:(NSNumber *)value forKey:(NSString *)key {
  if ([self isValidKey:key]) {
    if (value) {
      [self.properties setObject:value forKey:key];
    } else {
      MSLogError([MSMobileCenter logTag], kValueNullErrorMessage);
    }
  }
  return self;
}

- (MSCustomProperties *)setBool:(BOOL)value forKey:(NSString *)key {
  if ([self isValidKey:key]) {
    [self.properties setObject:[NSNumber numberWithBool:value] forKey:key];
  }
  return self;
}

- (MSCustomProperties *)setDate:(NSDate *)value forKey:(NSString *)key {
  if ([self isValidKey:key]) {
    if (value) {
      [self.properties setObject:value forKey:key];
    } else {
      MSLogError([MSMobileCenter logTag], kValueNullErrorMessage);
    }
  }
  return self;
}

- (MSCustomProperties *)clearPropertyForKey:(NSString *)key {
  if ([self isValidKey:key]) {
    [self.properties setObject:[NSNull null] forKey:key];
  }
  return self;
}

- (BOOL) isValidKey:(NSString *)key {
  static NSRegularExpression *regex = nil;
  if (!regex) {
    NSError *error = nil;
    regex = [NSRegularExpression regularExpressionWithPattern:kKeyPattern options:0 error:&error];
  }
  if (!key || ![regex matchesInString:key options:0 range:NSMakeRange(0, key.length)].count) {
    MSLogError([MSMobileCenter logTag], @"Custom property \"%@\" must match \"%@\"", key, kKeyPattern);
    return NO;
  }
  if ([self.properties objectForKey:key]) {
    MSLogWarning([MSMobileCenter logTag], @"Custom property \"%@\" is already set or cleared and will be overridden.", key);
  }
  return YES;
}

@end
