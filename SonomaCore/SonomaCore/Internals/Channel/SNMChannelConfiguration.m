/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMChannelConfiguration.h"

static SNMChannelConfiguration *SNMChannelConfigurationDefault;
static SNMChannelConfiguration *SNMChannelConfigurationHigh;
static SNMChannelConfiguration *SNMChannelConfigurationBackground;

@implementation SNMChannelConfiguration

- (instancetype)initWithPriorityName:(NSString *)name
                       flushInterval:(float)flushInterval
                      batchSizeLimit:(NSUInteger)batchSizeLimit
                 pendingBatchesLimit:(NSUInteger)pendingBatchesLimit {
  if (self = [super init]) {
    _name = name;
    _flushInterval = flushInterval;
    _batchSizeLimit = batchSizeLimit;
    _pendingBatchesLimit = pendingBatchesLimit;
  }
  return self;
}

+ (instancetype)configurationForPriority:(SNMPriority)priority {
  switch (priority) {

  case SNMPriorityHigh:
    if (!SNMChannelConfigurationHigh) {
      SNMChannelConfigurationHigh = [[self alloc] initWithPriorityName:@"SNMPriorityHigh"
                                                         flushInterval:3.0
                                                        batchSizeLimit:1
                                                   pendingBatchesLimit:6];
    }
    return SNMChannelConfigurationHigh;

  case SNMPriorityBackground:
    if (!SNMChannelConfigurationBackground) {
      SNMChannelConfigurationBackground = [[self alloc] initWithPriorityName:@"SNMPriorityBackground"
                                                               flushInterval:60.0
                                                              batchSizeLimit:100
                                                         pendingBatchesLimit:1];
    }
    return SNMChannelConfigurationBackground;

  default:
    if (!SNMChannelConfigurationDefault) {
      SNMChannelConfigurationDefault = [[self alloc] initWithPriorityName:@"SNMPriorityDefault"
                                                            flushInterval:3.0
                                                           batchSizeLimit:50
                                                      pendingBatchesLimit:3];
    }
    return SNMChannelConfigurationDefault;
  }
}

+ (NSArray<SNMChannelConfiguration *> *)allConfigurations {
  return @[
    [SNMChannelConfiguration configurationForPriority:SNMChannelConfigurationDefault],
    [SNMChannelConfiguration configurationForPriority:SNMChannelConfigurationHigh],
    [SNMChannelConfiguration configurationForPriority:SNMChannelConfigurationBackground]
  ];
}

@end
