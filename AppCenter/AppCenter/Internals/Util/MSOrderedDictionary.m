#import "MSOrderedDictionaryPrivate.h"

@implementation MSOrderedDictionary

- (instancetype)init {
  if ((self = [super init])) {
    _dictionary = [NSMutableDictionary new];
    _order = [NSMutableArray new];
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  self = [super init];
  if (self != nil) {
    _dictionary = [[NSMutableDictionary alloc] initWithCapacity:numItems];
    _order = [NSMutableArray new];
  }
  return self;
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
  if (!self.dictionary[aKey]) {
    [self.order addObject:aKey];
  }
  self.dictionary[aKey] = anObject;
}

- (NSEnumerator *)keyEnumerator {
  return [self.order objectEnumerator];
}

- (id)objectForKey:(id)key {
  return self.dictionary[key];
}

- (NSUInteger)count {
  return [self.dictionary count];
}

- (void)removeAllObjects {
  [self.dictionary removeAllObjects];
}

- (BOOL)isEqualToDictionary:(NSDictionary *)otherDictionary {
  if (![(NSObject *)otherDictionary isKindOfClass:[NSDictionary class]] || ![super isEqualToDictionary:otherDictionary]) {
    return NO;
  }
  if ([otherDictionary count] != [self.dictionary count]) {
    return NO;
  }
  NSEnumerator *keyEnumeratorMine = [self keyEnumerator];
  NSEnumerator *keyEnumeratorTheirs = [otherDictionary keyEnumerator];
  NSObject *nextKeyMine = [keyEnumeratorMine nextObject];
  NSObject *nextKeyTheirs = [keyEnumeratorTheirs nextObject];
  if (nextKeyMine == nil && nextKeyTheirs == nil) {
    return YES;
  }
  while (nextKeyMine != nil && nextKeyTheirs != nil) {
    if (nextKeyMine != nextKeyTheirs || self.dictionary[nextKeyMine] != otherDictionary[nextKeyTheirs]) {
      return NO;
    }
    nextKeyMine = [keyEnumeratorMine nextObject];
    nextKeyTheirs = [keyEnumeratorTheirs nextObject];
  }
  return YES;
}

@end
