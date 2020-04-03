// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterUserDefaults.h"
#import "MSAppCenterInternal.h"
#import "MSLogger.h"

static NSString *const kMSAppCenterUserDefaultsMigratedKey = @"310UserDefaultsMigratedKey";

static MSAppCenterUserDefaults *sharedInstance = nil;
static dispatch_once_t onceToken;

// MSAppCenterUserDefaults keys to be migrated.
static NSMutableDictionary *keysToMigrate;

@implementation MSAppCenterUserDefaults

+ (void)load {
  keysToMigrate = [NSMutableDictionary new];
}

+ (void)addKeysToMigrate:(NSDictionary *)keys {
  [keysToMigrate addEntriesFromDictionary:keys];
}

+ (instancetype)shared {
  dispatch_once(&onceToken, ^{
    sharedInstance = [[MSAppCenterUserDefaults alloc] init];
    NSDictionary *changedKeys = @{
      @"MSAppCenterChannelStartTimer" : MSPrefixKeyFrom(@"MSChannelStartTimer"),
                                                                        // [MSChannelUnitDefault oldestPendingLogTimestampKey]
      @"MSAppCenterPastDevices" : @"pastDevicesKey",                    // [MSDeviceTracker init],
                                                                        // [MSDeviceTracker device],
                                                                        // [MSDeviceTracker clearDevices]
      @"MSAppCenterInstallId" : @"MSInstallId",                         // [MSAppCenterInternal installId]
      @"MSAppCenterAppCenterIsEnabled" : @"MSAppCenterIsEnabled",       // [MSAppCenter isEnabled]
      @"MSAppCenterEncryptionKeyMetadata" : @"MSEncryptionKeyMetadata", // [MSEncrypter getCurrentKeyTag],
                                                                        // [MSEncrypter rotateToNewKeyTag]
      @"MSAppCenterSessionIdHistory" : @"SessionIdHistory",             // [MSSessionContext init],
                                                                        // [MSSessionContext setSessionId],
                                                                        // [MSSessionContext clearSessionHistoryAndKeepCurrentSession]
      @"MSAppCenterUserIdHistory" : @"UserIdHistory"                    // [MSUserIdContext init], [MSUserIdContext setUserId],
                                                                        // [MSUserIdContext clearUserIdHistory]
    };
    [keysToMigrate addEntriesFromDictionary:changedKeys];
    [sharedInstance migrateKeys:keysToMigrate];
  });
  return sharedInstance;
}

+ (NSDictionary *)keysToMigrate {
  return keysToMigrate;
}

+ (void)resetSharedInstance {

  // Reset the once_token so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
  [keysToMigrate removeAllObjects];
}

- (void)migrateKeys:(NSDictionary *)migratedKeys {
  NSNumber *hasMigrated = [self objectForKey:kMSAppCenterUserDefaultsMigratedKey];
  if (hasMigrated) {
    return;
  }

  MSLogVerbose([MSAppCenter logTag], @"Migrating the old NSDefaults keys to new ones.");
  for (NSObject *newKey in migratedKeys) {
    if (![newKey isKindOfClass:[NSString class]]) {
      MSLogError([MSAppCenter logTag], @"Unsupported type %@ for key %@", [newKey class], newKey);
      continue;
    }
    id<NSObject> oldKey = migratedKeys[newKey];
    NSString *newKeyString = (NSString *)newKey;
    if ([oldKey isKindOfClass:[NSString class]]) {
      id value = [[NSUserDefaults standardUserDefaults] objectForKey:(NSString *)oldKey];
      [self swapKeys:(NSString *)oldKey newKey:newKeyString value:value];
    } else if ([oldKey isKindOfClass:[MSUserDefaultsPrefixKey class]]) {

      // List all the keys starting with oldKey.
      NSString *oldKeyPrefix = ((MSUserDefaultsPrefixKey *)oldKey).keyPrefix;
      NSArray *userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
      for (NSString *userDefaultsKey in userDefaultKeys) {
        if ([userDefaultsKey hasPrefix:oldKeyPrefix]) {
          NSString *suffix = [userDefaultsKey stringByReplacingOccurrencesOfString:oldKeyPrefix withString:@""];
          NSString *newKeyWithSuffix = [newKeyString stringByAppendingString:suffix];
          id value = [[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsKey];
          [self swapKeys:userDefaultsKey newKey:newKeyWithSuffix value:value];
        }
      }
    } else {
      MSLogError([MSAppCenter logTag], @"Unsupported type %@ for key %@", [oldKey class], oldKey);
      continue;
    }
  }
  [self setObject:@YES forKey:kMSAppCenterUserDefaultsMigratedKey];
}

- (void)swapKeys:(NSString *)oldKey newKey:(NSString *)newKey value:(id)value {
  if (value == nil) {
    return;
  }
  [[NSUserDefaults standardUserDefaults] setObject:value forKey:newKey];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:oldKey];
  MSLogVerbose([MSAppCenter logTag], @"Migrating key %@ -> %@", oldKey, newKey);
}

- (NSString *)getAppCenterKeyFrom:(NSObject *)key {
  if (![key isKindOfClass:[NSString class]]) {
    MSLogError([MSAppCenter logTag], @"Unsupported type %@ for key %@", [key class], key);
    return nil;
  }
  NSString *keyString = (NSString *)key;
  NSAssert(![keyString hasPrefix:kMSUserDefaultsPrefix], @"Please do not prepend the key with 'MSAppCenter'. It's done automatically.");
  return [kMSUserDefaultsPrefix stringByAppendingString:keyString];
}

- (id)objectForKey:(NSObject *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  return [[NSUserDefaults standardUserDefaults] objectForKey:keyPrefixed];
}

- (void)setObject:(id)value forKey:(NSObject *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  [[NSUserDefaults standardUserDefaults] setObject:value forKey:keyPrefixed];
}

- (void)removeObjectForKey:(NSObject *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:keyPrefixed];
}

@end

@implementation MSUserDefaultsPrefixKey

- (instancetype)initWithPrefix:(NSString *)prefix {
  if ((self = [super init])) {
    _keyPrefix = prefix;
  }
  return self;
}

- (id)copyWithZone:(nullable __unused NSZone *)zone {
  return [[MSUserDefaultsPrefixKey alloc] initWithPrefix:self.keyPrefix];
}

@end
