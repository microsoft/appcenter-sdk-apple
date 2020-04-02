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
      [[MSUserDefaultsWildcardKey alloc] initWithString:@"MSChannelStartTimer"] : @"MSAppCenterChannelStartTimer",
                                                                        // [MSChannelUnitDefault oldestPendingLogTimestampKey]
      @"pastDevicesKey" : @"MSAppCenterPastDevices",                    // [MSDeviceTrackerPrivate init],
                                                                        // [MSDeviceTrackerPrivate device],
                                                                        // [MSDeviceTrackerPrivate clearDevices]
      @"MSInstallId" : @"MSAppCenterInstallId",                         // [MSAppCenterInternal installId]
      @"MSAppCenterIsEnabled" : @"MSAppCenterAppCenterIsEnabled",       // [MSAppCenter isEnabled]
      @"MSEncryptionKeyMetadata" : @"MSAppCenterEncryptionKeyMetadata", // [MSEncrypterPrivate getCurrentKeyTag],
                                                                        // [MSEncrypterPrivate rotateToNewKeyTag]
      @"SessionIdHistory" : @"MSAppCenterSessionIdHistory",             // [MSSessionContext init],
                                                                        // [MSSessionContext setSessionId],
                                                                        // [MSSessionContext clearSessionHistoryAndKeepCurrentSession]
      @"UserIdHistory" : @"MSAppCenterUserIdHistory"                    // [MSUserIdContext init], [MSUserIdContext setUserId],
                                                                        // [MSUserIdContext clearUserIdHistory]
    };
    [keysToMigrate addEntriesFromDictionary:changedKeys];
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
  [keysToMigrate removeAllObjects];
}

- (void)migrateKeys:(NSDictionary *)migratedKeys {
  NSNumber *hasMigrated = [self objectForKey:kMSAppCenterUserDefaultsMigratedKey];
  if (hasMigrated) {
    return;
  }
  MSLogVerbose([MSAppCenter logTag], @"Migrating the old NSDefaults keys to new ones.");
  for (NSString *oldKey in [migratedKeys allKeys]) {
    BOOL wildcardUsed = [oldKey isKindOfClass:[MSUserDefaultsWildcardKey class]];
    NSString *newKey = migratedKeys[oldKey];
    NSMutableArray *oldValues = [NSMutableArray new];
    NSMutableArray *newKeys = [NSMutableArray new];
    NSMutableArray *oldKeys = [NSMutableArray new];
    if (!wildcardUsed) {
      id value = [[NSUserDefaults standardUserDefaults] objectForKey:oldKey];
      if (value != nil) {
        [oldValues addObject:value];
        [newKeys addObject:newKey];
        [oldKeys addObject:oldKey];
      }
    } else {

      // List all the keys starting with oldKey.
      NSString *oldKeyPrefix = [oldKey substringToIndex:oldKey.length - 1];
      NSArray *userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
      for (NSString *userDefaultsKey in userDefaultKeys) {
        if ([userDefaultsKey hasPrefix:oldKeyPrefix]) {
          NSString *suffix = [userDefaultsKey stringByReplacingOccurrencesOfString:oldKeyPrefix withString:@""];
          NSString *newKeyWithSuffix = [newKey stringByAppendingString:suffix];
          id value = [[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsKey];
          if (value == nil) {
            continue;
          }
          [oldValues addObject:value];
          [newKeys addObject:newKeyWithSuffix];
          [oldKeys addObject:userDefaultsKey];
        }
      }
    }
    for (NSUInteger i = 0; i < oldValues.count; i++) {
      id value = oldValues[i];
      NSString *newKeyWithSuffix = newKeys[i];
      NSString *oldKeyFull = oldKeys[i];

      [[NSUserDefaults standardUserDefaults] setObject:value forKey:newKeyWithSuffix];
      [[NSUserDefaults standardUserDefaults] removeObjectForKey:oldKeyFull];
      MSLogVerbose([MSAppCenter logTag], @"Migrating key %@ -> %@", oldKeyFull, newKeyWithSuffix);
    }
  }
  [self setObject:@YES forKey:kMSAppCenterUserDefaultsMigratedKey];
}

- (NSString *)getAppCenterKeyFrom:(NSString *)key {
  NSAssert(![key hasPrefix:kMSUserDefaultsPrefix], @"Please do not prepend the key with 'MSAppCenter'. It's done automatically.");
  return [kMSUserDefaultsPrefix stringByAppendingString:key];
}

- (id)objectForKey:(NSString *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  return [[NSUserDefaults standardUserDefaults] objectForKey:keyPrefixed];
}

- (void)setObject:(id)value forKey:(NSString *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  [[NSUserDefaults standardUserDefaults] setObject:value forKey:keyPrefixed];
}

- (void)removeObjectForKey:(NSString *)key {
  NSString *keyPrefixed = [self getAppCenterKeyFrom:key];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:keyPrefixed];
}

@end

@implementation MSUserDefaultsWildcardKey

- (instancetype)initWithString:(NSString *)aString {
    return [super initWithString:aString];
}

- (NSUInteger)length {
    return [super length];
}

- (unichar)characterAtIndex:(NSUInteger)index {
    return [super characterAtIndex:index];
}

@end
