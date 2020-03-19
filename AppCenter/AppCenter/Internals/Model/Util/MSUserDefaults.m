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
  
  // Key -> MSKey
  [keys addObject:[key stringByReplacingOccurrencesOfString:kMSUserDefaultsPrefix withString:@""]];
  
  // TBD:
  // key -> MSKey
  // kMSKey -> MSKey
  // NSKey -> MSKey
  return keys;
}

- (id)objectForKey:(NSString *)key {
  
  // Get values by deprecated versions of keys.
  NSMutableArray<NSString *> *oldKeys = [self getDeprecatedKeysFrom:key];
  for(NSString *oldKey in oldKeys) {
    id oldValue = [[NSUserDefaults standardUserDefaults] objectForKey:oldKey];
    if (oldValue != nil) {
      
      // If we found the value by a deprecated key, re-save the value and return it.
      [self setObject:oldValue forKey:key];
      MSLogVerbose([MSAppCenter logTag], @"Migrating the value from old key %@ to %@", oldKey, key);
      [self removeObjectForKey:oldKey];
      return oldValue;
    }
  }
  
  // If there are no deprecated entries, simply return the value.
  return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)setObject:(id)o forKey:(NSString *)key {
  [[NSUserDefaults standardUserDefaults] setObject:o forKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
  NSMutableArray<NSString *> *oldKeys = [self getDeprecatedKeysFrom:key];
  for(NSString *oldKey in oldKeys) {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:oldKey];
  }
}

- (NSDictionary *)updateDictionary:(NSDictionary *)dict forKey:(NSString *)key expiration:(float)expiration {
  NSMutableDictionary *update = [[NSMutableDictionary alloc] initWithDictionary:dict];

  // Get from local store.
  NSMutableArray<NSString *> *oldKeys = [self getDeprecatedKeysFrom:key];
  NSDictionary *store;
  for(NSString *oldKey in oldKeys) {
    store = [[NSUserDefaults standardUserDefaults] dictionaryForKey:oldKey];
    if (store != nil) {
      [self removeObjectForKey:oldKey];
      MSLogVerbose([MSAppCenter logTag], @"Migrating the dictionary from old key %@ to %@", oldKey, key);
      break;
    }
  }
  if (store == nil) {
    store = [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
  }
  
  CFAbsoluteTime ts = [(NSNumber *)store[kMSUserDefaultsTs] doubleValue];
  MSLogVerbose([MSAppCenter logTag], @"Settings:store[%@]=%@", key, store);

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
    MSLogDebug([MSAppCenter logTag], @"Settings:update[%@]=%@", key, update);

    // Copy store as a mutable version.
    NSMutableDictionary *d = [store mutableCopy];
    if (d == nil)
      d = [[NSMutableDictionary alloc] initWithCapacity:[update count]];

    // Append update to the current store.
    [d addEntriesFromDictionary:update];

    // Set new timestamp.
    d[kMSUserDefaultsTs] = @(CFAbsoluteTimeGetCurrent());

    // Save.
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:key];
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
