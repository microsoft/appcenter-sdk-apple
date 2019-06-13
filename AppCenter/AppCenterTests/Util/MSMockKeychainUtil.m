// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSMockKeychainUtil.h"
#import "MSTestFrameworks.h"

static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *stringsDictionary;
static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSMutableArray *> *> *arraysDictionary;
static NSString *kMSDefaultServiceName = @"DefaultServiceName";

@interface MSMockKeychainUtil ()

@property(nonatomic) id mockKeychainUtil;

@end

@implementation MSMockKeychainUtil

+ (void)load {
  stringsDictionary = [NSMutableDictionary new];
  arraysDictionary = [NSMutableDictionary new];
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
  if (!stringsDictionary[serviceName]) {
    stringsDictionary[serviceName] = [NSMutableDictionary new];
  }
  stringsDictionary[serviceName][key] = string;
  return YES;
}

+ (NSString *_Nullable)deleteStringForKey:(NSString *)key {
  return [self deleteStringForKey:key withServiceName:kMSDefaultServiceName];
}

+ (NSString *_Nullable)deleteStringForKey:(NSString *)key withServiceName:(NSString *)serviceName {
  NSString *value = stringsDictionary[serviceName][key];
  [stringsDictionary[serviceName] removeObjectForKey:key];
  return value;
}

+ (NSString *_Nullable)stringForKey:(NSString *)key {
  return [self stringForKey:key withServiceName:kMSDefaultServiceName];
}

+ (NSString *_Nullable)stringForKey:(NSString *)key withServiceName:(NSString *)serviceName {
  return stringsDictionary[serviceName][key];
}

+ (BOOL)clear {
  [stringsDictionary[kMSDefaultServiceName] removeAllObjects];
  [arraysDictionary removeAllObjects];
  return YES;
}

- (void)stopMocking {
  [stringsDictionary removeAllObjects];
  [arraysDictionary removeAllObjects];
  [self.mockKeychainUtil stopMocking];
}

@end
