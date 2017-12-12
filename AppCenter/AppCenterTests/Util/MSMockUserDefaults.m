#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUserDefaults.h"

@interface MSMockUserDefaults ()

@property(nonatomic) NSMutableDictionary<NSString *, NSObject *> *dictionary;
@property(nonatomic) id mockNSUserDefaults;
@property(nonatomic) id mockMSUserDefaults;

@end

@implementation MSMockUserDefaults

- (instancetype)init {
  self = [super init];
  if (self) {
    _dictionary = [NSMutableDictionary new];
    _mockNSUserDefaults = OCMClassMock([NSUserDefaults class]);
    OCMStub([_mockNSUserDefaults objectForKey:OCMOCK_ANY]).andCall(self, @selector(objectForKey:));
    OCMStub([_mockNSUserDefaults setObject:OCMOCK_ANY forKey:OCMOCK_ANY]).andCall(self, @selector(setObject:forKey:));
    OCMStub([_mockNSUserDefaults removeObjectForKey:OCMOCK_ANY]).andCall(self, @selector(removeObjectForKey:));
    OCMStub([_mockNSUserDefaults standardUserDefaults]).andReturn(self.mockNSUserDefaults);

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
  [self.mockNSUserDefaults stopMocking];
  [self.mockMSUserDefaults stopMocking];
}

@end
