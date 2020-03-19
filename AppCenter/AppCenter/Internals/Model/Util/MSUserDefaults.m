// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterInternal.h"
#import "MSLogger.h"
#import "MSUserDefaults.h"

static NSString *const kMSUserDefaultsTs = @"_ts";
static NSString *const kMSUserDefaultsPrefix = @"MS";

@implementation MSUserDefaults

+ (instancetype)shared {
  static MSUserDefaults *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[MSUserDefaults alloc] init];
  });
  return sharedInstance;
}

- (NSMutableArray<NSString *> *)getDeprecatedKeysFrom:(NSString *)key {
  NSMutableArray<NSString *> *keys = [NSMutableArray new];
  
  if (![key hasPrefix:kMSUserDefaultsPrefix]) {
    MSLogWarning([MSAppCenter logTag], @"Trying to retrieve a value by an incorrect key %@. All keys must start with %@", key, kMSUserDefaultsPrefix);
    return keys;
  }
  
  // Key -> MSKey
  NSString *keyWithoutMSPrefix = [key substringFromIndex:2];
  [keys addObject:keyWithoutMSPrefix];
  
  // key -> MSKey
  NSString *firstLetterLowercased = [[keyWithoutMSPrefix substringToIndex:1] lowercaseString];
  NSString *keyWithoutMSPrefixStartingWithLowercase = [firstLetterLowercased stringByAppendingString:[keyWithoutMSPrefix substringFromIndex:1]];
  [keys addObject:keyWithoutMSPrefixStartingWithLowercase];
  
  // kMSKey -> MSKey
  NSString *keyStartingFromK = [@"k" stringByAppendingString:key];
  [keys addObject:keyStartingFromK];
  
  // NSKey -> MSKey
  NSString *keyWithNSPrefix = [@"NS" stringByAppendingString:keyWithoutMSPrefix];
  [keys addObject:keyWithNSPrefix];
  return keys;
}

- (id)objectForKey:(NSString *)key {
  NSString *keyPrefixed = [kMSUserDefaultsPrefix stringByAppendingString:key];
  
  // Get values by deprecated versions of keys.
  NSMutableArray<NSString *> *oldKeys = [self getDeprecatedKeysFrom:keyPrefixed];
  for(NSString *oldKey in oldKeys) {
    id oldValue = [[NSUserDefaults standardUserDefaults] objectForKey:oldKey];
    if (oldValue != nil) {
      
      // If we found the value by a deprecated key, re-save the value and return it.
      [self setObject:oldValue forKey:keyPrefixed];
      MSLogVerbose([MSAppCenter logTag], @"Migrating the value from old key %@ to %@", oldKey, keyPrefixed);
      [self removeObjectForKey:oldKey];
      return oldValue;
    }
  }
  
  // If there are no deprecated entries, simply return the value.
  return [[NSUserDefaults standardUserDefaults] objectForKey:keyPrefixed];
}

- (void)setObject:(id)o forKey:(NSString *)key {
  NSString *keyPrefixed = [kMSUserDefaultsPrefix stringByAppendingString:key];
  [[NSUserDefaults standardUserDefaults] setObject:o forKey:keyPrefixed];
}

- (void)removeObjectForKey:(NSString *)key {
  NSString *keyPrefixed = [kMSUserDefaultsPrefix stringByAppendingString:key];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:keyPrefixed];
  NSMutableArray<NSString *> *oldKeys = [self getDeprecatedKeysFrom:keyPrefixed];
  for(NSString *oldKey in oldKeys) {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:oldKey];
  }
}

- (NSDictionary *)updateDictionary:(NSDictionary *)dict forKey:(NSString *)key expiration:(float)expiration {
  NSString *keyPrefixed = [kMSUserDefaultsPrefix stringByAppendingString:key];
  NSMutableDictionary *update = [[NSMutableDictionary alloc] initWithDictionary:dict];

  // Get from local store.
  NSMutableArray<NSString *> *oldKeys = [self getDeprecatedKeysFrom:keyPrefixed];
  NSDictionary *store;
  for(NSString *oldKey in oldKeys) {
    store = [[NSUserDefaults standardUserDefaults] dictionaryForKey:oldKey];
    if (store != nil) {
      [self removeObjectForKey:oldKey];
      MSLogVerbose([MSAppCenter logTag], @"Migrating the dictionary from old key %@ to %@", oldKey, keyPrefixed);
      break;
    }
  }
  if (store == nil) {
    store = [[NSUserDefaults standardUserDefaults] dictionaryForKey:keyPrefixed];
  }
  
  CFAbsoluteTime ts = [(NSNumber *)store[kMSUserDefaultsTs] doubleValue];
  MSLogVerbose([MSAppCenter logTag], @"Settings:store[%@]=%@", keyPrefixed, store);

  // Force update if timestamp expiration is reached.
  if (ts <= 0.0 || expiration <= 0.0f || fabs(CFAbsoluteTimeGetCurrent() - ts) < (double)expiration) {

    // Remove if already in store and value is the same.
    for (NSString *k in [store allKeys]) {
      if (update[k] != nil && [(NSObject *)update[k] isEqual:store[k]])
        [update removeObjectForKey:k];
    }
  }

  // If still values to update.
  if ([update count] > 0) {
    MSLogDebug([MSAppCenter logTag], @"Settings:update[%@]=%@", keyPrefixed, update);

    // Copy store as a mutable version.
    NSMutableDictionary *d = [store mutableCopy];
    if (d == nil)
      d = [[NSMutableDictionary alloc] initWithCapacity:[update count]];

    // Append update to the current store.
    [d addEntriesFromDictionary:update];

    // Set new timestamp.
    d[kMSUserDefaultsTs] = @(CFAbsoluteTimeGetCurrent());

    // Save.
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:keyPrefixed];
  }

  return update;
}

- (NSDictionary *)updateDictionary:(NSDictionary *)dict forKey:(NSString *)key {
  return [self updateDictionary:dict forKey:key expiration:0.0];
}

- (BOOL)updateObject:(id)o forKey:(NSString *)key expiration:(float)expiration {
  NSDictionary *update = [self updateDictionary:@{ @"v" : o } forKey:key expiration:expiration];
  return update[@"v"] != nil;
}

- (BOOL)updateObject:(id)o forKey:(NSString *)key {
  return [self updateObject:o forKey:key expiration:0.0];
}

@end
