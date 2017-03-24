#import <OCMock/OCMock.h>
#import "MSMockUserDefaults.h"

@interface MSMockUserDefaults()

@property(nonatomic) NSMutableDictionary<NSString*,NSObject*> *dictionary;
@property(nonatomic) id mockUserDefaults;

@end

@implementation MSMockUserDefaults

@synthesize dictionary;
@synthesize mockUserDefaults;

- (instancetype)init {
  self = [super init];
  if (self) {
    self.dictionary = [NSMutableDictionary new];
    self.mockUserDefaults = OCMClassMock([NSUserDefaults class]);
    OCMStub([self.mockUserDefaults standardUserDefaults]).andReturn(self.mockUserDefaults);
    OCMStub([self.mockUserDefaults objectForKey:[OCMArg any]]).andCall(self,@selector(objectForKey:));
    OCMStub([self.mockUserDefaults setObject:[OCMArg any] forKey:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
      id object;
      [invocation getArgument:&object atIndex:2];

      // Don't store nil objects.
      if (!object) {
        return;
      }
      id key;
      [invocation getArgument:&key atIndex:3];
      [self.dictionary setObject:object forKey:key];
    });
    OCMStub([self.mockUserDefaults removeObjectForKey:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
      id key;
      [invocation getArgument:&key atIndex:2];
      [self.dictionary removeObjectForKey:key];
    });
  }
  return self;
}

-(void)setObject:(NSObject*)anObject forKey:(NSString*)aKey {
  [self.mockUserDefaults setObject:anObject forKey:aKey];
}

-(nullable id)objectForKey:(NSString*)aKey {
  return self.dictionary[aKey];
}

- (void)removeObjectForKey:(NSString *)aKey {
  [self.mockUserDefaults removeObjectForKey:aKey];
}

-(void)stopMocking {
  [self.dictionary removeAllObjects];
  [self.mockUserDefaults stopMocking];
}

@end
