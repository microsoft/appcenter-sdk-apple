#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUserDefaults.h"

@interface MSMockUserDefaults ()

@property(nonatomic) NSMutableDictionary<NSString *, NSObject *> *dictionary;
@property(nonatomic) id mockMSUserDefaults;

@end

@implementation MSMockUserDefaults

- (instancetype)init {
  self = [super init];
  if (self) {
    _dictionary = [NSMutableDictionary new];

    // Mock MSUserDefaults shared method to return this instance.
    _mockMSUserDefaults = OCMClassMock([MSUserDefaults class]);
    OCMStub([_mockMSUserDefaults shared]).andReturn(self);
  }
  return self;
}

- (void)setObject:(id)anObject forKey:(NSString *)aKey {

  // Don't store nil objects.
  if (!anObject) {
    return;
  }
  [self.dictionary setObject:anObject forKey:aKey];
}

- (nullable id)objectForKey:(NSString *)aKey {
  return self.dictionary[aKey];
}

- (void)removeObjectForKey:(NSString *)aKey {
  [self.dictionary removeObjectForKey:aKey];
}

- (void)stopMocking {
  [self.dictionary removeAllObjects];
  [self.mockMSUserDefaults stopMocking];
}

@end
