#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUserDefaults.h"

@interface MSMockUserDefaults()

@property(nonatomic) NSMutableDictionary<NSString*,NSObject*> *dictionary;
@property(nonatomic) id mockUserDefaults;

@end

@implementation MSMockUserDefaults

- (instancetype)init {
  self = [super init];
  if (self) {
    _dictionary = [NSMutableDictionary new];
    _mockUserDefaults = OCMClassMock([NSUserDefaults class]);
    OCMStub([_mockUserDefaults objectForKey:[OCMArg any]]).andCall(self,@selector(objectForKey:));
    OCMStub([_mockUserDefaults setObject:[OCMArg any] forKey:[OCMArg any]]).andCall(self,@selector(setObject:forKey:));
    OCMStub([_mockUserDefaults removeObjectForKey:[OCMArg any]]).andCall(self,@selector(removeObjectForKey:));
    OCMStub([_mockUserDefaults standardUserDefaults]).andReturn(self.mockUserDefaults);
    
    // Mock MSUserDefaults shared method to return this instance.
    id userDefaultsMock = OCMClassMock([MSUserDefaults class]);
    OCMStub([userDefaultsMock shared]).andReturn(self);
  }
  return self;
}

-(void)setObject:(id)anObject forKey:(NSString*)aKey {
  
  // Don't store nil objects.
  if (!anObject) {
    return;
  }
  [self.dictionary setObject:anObject forKey:aKey];
}

-(nullable id)objectForKey:(NSString*)aKey {
  return self.dictionary[aKey];
}

- (void)removeObjectForKey:(NSString *)aKey {
  [self.dictionary removeObjectForKey:aKey];
}

-(void)stopMocking {
  [self.dictionary removeAllObjects];
  [self.mockUserDefaults stopMocking];
}

@end
