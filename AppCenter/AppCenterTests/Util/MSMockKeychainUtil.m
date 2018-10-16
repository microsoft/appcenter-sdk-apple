#import "MSMockKeychainUtil.h"
#import "MSTestFrameworks.h"

static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *dictionary;
static NSString *kMSDefaultServiceName = @"DefaultServiceName";

@interface MSMockKeychainUtil ()

@property(nonatomic) id mockKeychainUtil;

@end

@implementation MSMockKeychainUtil

+ (void)load {
  dictionary = [NSMutableDictionary new];
}

- (instancetype)init {
  self = [super init];
  if (self) {

    // Mock MSUserDefaults shared method to return this instance.
    _mockKeychainUtil = OCMClassMock([MSKeychainUtil class]);
    OCMStub([_mockKeychainUtil storeString:[OCMArg any] forKey:[OCMArg any]]).andCall([self class], @selector(storeString:forKey:));
    OCMStub([_mockKeychainUtil storeString:[OCMArg any] forKey:[OCMArg any] withServiceName:[OCMArg any]])
        .andCall([self class], @selector(storeString:forKey:withServiceName:));
    OCMStub([_mockKeychainUtil deleteStringForKey:[OCMArg any]]).andCall([self class], @selector(deleteStringForKey:));
    OCMStub([_mockKeychainUtil deleteStringForKey:[OCMArg any] withServiceName:[OCMArg any]])
        .andCall([self class], @selector(deleteStringForKey:withServiceName:));
    OCMStub([_mockKeychainUtil stringForKey:[OCMArg any]]).andCall([self class], @selector(stringForKey:));
    OCMStub([_mockKeychainUtil stringForKey:[OCMArg any] withServiceName:[OCMArg any]])
        .andCall([self class], @selector(stringForKey:withServiceName:));
    OCMStub([_mockKeychainUtil clear]).andCall([self class], @selector(clear));
  }
  return self;
}

+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key {
  return [self storeString:string forKey:key withServiceName:kMSDefaultServiceName];
}

+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key withServiceName:(NSString *)serviceName {

  // Don't store nil objects.
  if (!string) {
    return NO;
  }
  if (!dictionary[serviceName]) {
    dictionary[serviceName] = [NSMutableDictionary new];
  }
  dictionary[serviceName][key] = string;
  return YES;
}

+ (NSString *_Nullable)deleteStringForKey:(NSString *)key {
  return [self deleteStringForKey:key withServiceName:kMSDefaultServiceName];
}

+ (NSString *_Nullable)deleteStringForKey:(NSString *)key withServiceName:(NSString *)serviceName {
  [dictionary[serviceName] removeObjectForKey:key];
  return key;
}

+ (NSString *_Nullable)stringForKey:(NSString *)key {
  return [self stringForKey:key withServiceName:kMSDefaultServiceName];
}

+ (NSString *_Nullable)stringForKey:(NSString *)key withServiceName:(NSString *)serviceName {
  return dictionary[serviceName][key];
}

+ (BOOL)clear {
  [dictionary[kMSDefaultServiceName] removeAllObjects];
  return YES;
}

- (void)stopMocking {
  [dictionary removeAllObjects];
  [self.mockKeychainUtil stopMocking];
}

@end
