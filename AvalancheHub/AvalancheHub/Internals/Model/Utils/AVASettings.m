/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVALogger.h"
#import "AVASettings.h"
#import "AVAUtils.h"

static NSString *const kAESettingsTs = @"_ts";

@implementation AVASettings

+ (instancetype)shared {
  static AVASettings *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[AVASettings alloc] init];
  });
  return sharedInstance;
}

- (id)objectForKey:(NSString *)key {
  return [kAVAUserDefaults objectForKey:key];
}

- (void)setObject:(__nullable id)o forKey:(NSString *)key {
  [kAVAUserDefaults setObject:o forKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
  [kAVAUserDefaults removeObjectForKey:key];
}

- (NSDictionary *)updateDictionary:(NSDictionary *)dict forKey:(NSString *)key expiration:(float)expiration {
  NSMutableDictionary *update = [[NSMutableDictionary alloc] initWithDictionary:dict];

  /* Get from local store */
  NSDictionary *store = [kAVAUserDefaults dictionaryForKey:key];
  CFAbsoluteTime ts = [store[kAESettingsTs] floatValue];
  AVALogVerbose(@"Settings:store[%@]=%@", key, store);

  /* Force update if timestamp expiration is reached */
  if (ts <= 0.0 || expiration <= 0.0 || fabs(CFAbsoluteTimeGetCurrent() - ts) < expiration) {
    /* Remove if already in store and value is the same */
    for (NSString *k in [store allKeys]) {
      if (update[k] != nil && [update[k] isEqual:store[k]])
        [update removeObjectForKey:k];
    }
  }

  /* If still values to update */
  if ([update count] > 0) {
    AVALogDebug(@"Settings:update[%@]=%@", key, update);

    /* Copy store as a mutable version */
    NSMutableDictionary *d = [store mutableCopy];
    if (d == nil)
      d = [[NSMutableDictionary alloc] initWithCapacity:[update count]];

    /* Append update to the current store */
    [d addEntriesFromDictionary:update];

    /* Set new timestamp */
    d[kAESettingsTs] = @(CFAbsoluteTimeGetCurrent());

    /* Save */
    [kAVAUserDefaults setObject:d forKey:key];
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

- (void)synchronize {
  [kAVAUserDefaults synchronize];
}

@end
