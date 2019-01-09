#import "MSOrderedDictionary.h"

@implementation MSOrderedDictionary

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (instancetype)init {
  if ((self = [super init])) {
    dictionary = [NSMutableDictionary new];
    _order = [NSMutableArray new];
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  self = [super init];
  if (self != nil)
  {
    dictionary = [[NSMutableDictionary alloc] initWithCapacity:numItems];
    _order = [NSMutableArray new];
  }
  return self;
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
  if(!dictionary[aKey]) {
    [self.order addObject:aKey];
  }
  dictionary[aKey] = anObject;
}

- (NSEnumerator *)keyEnumerator {
  return [self.order objectEnumerator];
}

- (id)objectForKey:(id)key {
  return dictionary[key];
}

- (NSUInteger)count {
  return [dictionary count];
}

- (void)removeAllObjects {
  [dictionary removeAllObjects];
}

- (BOOL)isEqualToDictionary:(NSDictionary *)otherDictionary {
  if (![(NSObject *)otherDictionary isKindOfClass:[MSOrderedDictionary class]] ||
      ![super isEqualToDictionary:otherDictionary]) {
    return NO;
  }
  MSOrderedDictionary *dict = (MSOrderedDictionary*)otherDictionary;
  if ([dict count] != [dictionary count]) {
    return NO;
  }
  NSEnumerator *keyEnumeratorMine = [self keyEnumerator];
  NSEnumerator *keyEnumeratorTheirs = [dict keyEnumerator];
  NSObject *nextKeyMine = [keyEnumeratorMine nextObject];
  NSObject *nextKeyTheirs = [keyEnumeratorTheirs nextObject];
  if (nextKeyMine == nil && nextKeyTheirs == nil) {
    return YES;
  }
  while (nextKeyMine != nil && nextKeyTheirs != nil) {
    if (nextKeyMine != nextKeyTheirs || dictionary[nextKeyMine] != otherDictionary[nextKeyTheirs]) {
      return NO;
    }
    nextKeyMine = [keyEnumeratorMine nextObject];
    nextKeyTheirs = [keyEnumeratorTheirs nextObject];
  }
  return YES;
}

#pragma clang diagnostic pop

@end
