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

#pragma clang diagnostic pop

@end
