// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterUserDefaults.h"
#import "MSAppCenterInternal.h"
#import "MSLogger.h"

static NSString *const kMSUserDefaultsTs = @"_ts";
static NSString *const kMSValueKey = @"v";
static NSString *const kMSAppCenterUserDefaultsMigratedKey = @"310UserDefaultsMigratedKey";

static MSAppCenterUserDefaults *sharedInstance = nil;
static dispatch_once_t onceToken;

// MSAppCenterUserDefaults keys to be migrated.
static NSMutableDictionary<NSString *, NSString *> *keysToMigrate;

@implementation MSAppCenterUserDefaults

+ (void)load {
  keysToMigrate = [NSMutableDictionary new];
}

+ (void)addKeysToMigrate:(NSDictionary<NSString *, NSString *> *)keys {
  [keysToMigrate addEntriesFromDictionary:keys];
}

+ (instancetype)shared {
  dispatch_once(&onceToken, ^{
    sharedInstance = [[MSAppCenterUserDefaults alloc] init];
    NSDictionary *migratedKeys = @{
      @"MSChannelStartTimer" : @"MSAppCenterChannelStartTimer",         // MSChannelUnitDefault
      @"pastDevicesKey" : @"MSAppCenterPastDevicesKey",                 // MSDeviceTrackerPrivate
      @"MSInstallId" : @"MSAppCenterInstallId",                         // MSAppCenterInternal
      @"MSAppCenterIsEnabled" : @"MSAppCenterAppCenterIsEnabled",       // MSAppCenter
      @"MSEncryptionKeyMetadata" : @"MSAppCenterEncryptionKeyMetadata", // MSEncrypterPrivate
      @"SessionIdHistory" : @"MSAppCenterSessionIdHistory",             // MSSessionContext
      @"UserIdHistory" : @"MSAppCenterUserIdHistory"                    // MSUserIdContext
    };
    [keysToMigrate addEntriesFromDictionary:migratedKeys];
    [sharedInstance migrateKeys:keysToMigrate];
  });
  return sharedInstance;
}

+ (NSDictionary<NSString *, NSString *> *)keysToMigrate {
    return keysToMigrate;
}

+ (void)resetSharedInstance {

  // Reset the once_token so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
}

- (void)migrateKeys:(NSDictionary *)migratedKeys {
  NSNumber *hasMigrated = [self objectForKey:kMSAppCenterUserDefaultsMigratedKey];
  if (hasMigrated) {
    return;
  }
  MSLogVerbose([MSAppCenter logTag], @"Migrating the old NSDefaults keys to new ones.");
  for (NSString *oldKey in [migratedKeys allKeys]) {
    NSString *newKey = migratedKeys[oldKey];
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:oldKey];
    if (value != nil) {
      [[NSUserDefaults standardUserDefaults] setObject:value forKey:newKey];
      [[NSUserDefaults standardUserDefaults] removeObjectForKey:oldKey];
      MSLogVerbose([MSAppCenter logTag], @"Migrating the key %@ -> %@", oldKey, newKey);
    }
  }
  [self setObject:@(1) forKey:kMSAppCenterUserDefaultsMigratedKey];
}

- (NSString *)getAppCenterKeyFrom:(NSString *)key {
  NSAssert(![key hasPrefix:kMSUserDefaultsPrefix], @"Please do not prepend the key with 'MSAppCenter'. It's done automatically.");
  return [kMSUserDefaultsPrefix stringByAppendingString:key];
}

- (id)objectForKey:(NSString *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  return [[NSUserDefaults standardUserDefaults] objectForKey:keyPrefixed];
}

- (void)setObject:(id)o forKey:(NSString *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  [[NSUserDefaults standardUserDefaults] setObject:o forKey:keyPrefixed];
}

- (void)removeObjectForKey:(NSString *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:keyPrefixed];
}

- (NSDictionary *)updateDictionary:(NSDictionary *)dict forKey:(NSString *)key expiration:(float)expiration {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] initWithDictionary:dict];

  // Get from local store.
  NSDictionary *store = [[NSUserDefaults standardUserDefaults] dictionaryForKey:keyPrefixed];

  CFAbsoluteTime updateTimestamp = [(NSNumber *)store[kMSUserDefaultsTs] doubleValue];
  MSLogVerbose([MSAppCenter logTag], @"Settings:store[%@]=%@", keyPrefixed, store);

  // Force update if timestamp expiration is reached.
  if (updateTimestamp <= 0.0 || expiration <= 0.0f || fabs(CFAbsoluteTimeGetCurrent() - updateTimestamp) < (double)expiration) {

    // Remove if already in store and value is the same.
    for (NSString *storeKey in [store allKeys]) {
      if (updateDictionary[storeKey] != nil && [(NSObject *)updateDictionary[storeKey] isEqual:store[storeKey]]) {
        [updateDictionary removeObjectForKey:storeKey];
      }
    }
  }

  // If still values to update.
  if ([updateDictionary count] > 0) {
    MSLogDebug([MSAppCenter logTag], @"Settings:update[%@]=%@", keyPrefixed, updateDictionary);

    // Copy store as a mutable version.
    NSMutableDictionary *mutableStore = [store mutableCopy];
    if (mutableStore == nil) {
      mutableStore = [[NSMutableDictionary alloc] initWithCapacity:[updateDictionary count]];
    }

    // Append update to the current store.
    [mutableStore addEntriesFromDictionary:updateDictionary];

    // Set new timestamp.
    mutableStore[kMSUserDefaultsTs] = @(CFAbsoluteTimeGetCurrent());

    // Save.
    [[NSUserDefaults standardUserDefaults] setObject:mutableStore forKey:keyPrefixed];
  }

  return updateDictionary;
}

- (NSDictionary *)updateDictionary:(NSDictionary *)dict forKey:(NSString *)key {
  return [self updateDictionary:dict forKey:key expiration:0.0];
}

- (BOOL)updateObject:(id)value forKey:(NSString *)key expiration:(float)expiration {
  NSDictionary *update = [self updateDictionary:@{kMSValueKey : value} forKey:key expiration:expiration];
  return update[kMSValueKey] != nil;
}

- (BOOL)updateObject:(id)value forKey:(NSString *)key {
  return [self updateObject:value forKey:key expiration:0.0];
}

@end
