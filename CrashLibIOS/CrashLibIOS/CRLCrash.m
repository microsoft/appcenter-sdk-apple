/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "CRLCrash.h"

static NSMutableSet *crashTypes = nil;

@implementation CRLCrash

+ (void)initialize {
  static dispatch_once_t predicate = 0;

  dispatch_once(&predicate, ^{
      crashTypes = [[NSMutableSet alloc] init];
  });
}

+ (NSArray *)allCrashes {
  return crashTypes.allObjects;
}

+ (void)registerCrash:(CRLCrash *)crash {
  [crashTypes addObject:crash];
}

+ (void)unregisterCrash:(CRLCrash *)crash {
  [crashTypes removeObject:crash];
}

- (NSString *)category {
  return @"NONE";
}

- (NSString *)title {
  return @"NONE";
}

- (NSString *)desc {
  return @"NONE";
}

- (void)crash {
  NSLog(@"I'm supposed to crash here.");
}

@end
