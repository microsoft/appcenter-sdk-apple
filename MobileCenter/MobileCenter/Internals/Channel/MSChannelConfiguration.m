#import "MSChannelConfiguration.h"

//static MSChannelConfiguration *MSChannelConfigurationDefault;
//static MSChannelConfiguration *MSChannelConfigurationHigh;
//static MSChannelConfiguration *MSChannelConfigurationBackground;

@implementation MSChannelConfiguration

- (instancetype)initWithGroupID:(NSString *)groupID
                  flushInterval:(float)flushInterval
                 batchSizeLimit:(NSUInteger)batchSizeLimit
            pendingBatchesLimit:(NSUInteger)pendingBatchesLimit {
  if ((self = [super init])) {
    _groupID = groupID;
    _flushInterval = flushInterval;
    _batchSizeLimit = batchSizeLimit;
    _pendingBatchesLimit = pendingBatchesLimit;
  }
  return self;
}

+ (instancetype)configurationForPriority:(MSPriority)priority groupID:(NSString *)groupID {
  switch (priority) {

  case MSPriorityHigh:
      return [[self alloc] initWithGroupID:groupID
                                                   flushInterval:1.0
                                                  batchSizeLimit:10
                                             pendingBatchesLimit:6];
//    }
//    return MSChannelConfigurationHigh;

  case MSPriorityBackground:
//    if (!MSChannelConfigurationBackground) {
      return [[self alloc] initWithGroupID:groupID
                                                         flushInterval:60.0
                                                        batchSizeLimit:100
                                                   pendingBatchesLimit:1];
//    }
//    return MSChannelConfigurationBackground;

  default:
//    if (!MSChannelConfigurationDefault) {
      return [[self alloc] initWithGroupID:groupID    flushInterval:3.0
                                                     batchSizeLimit:50
                                                pendingBatchesLimit:3];
//    }
//    return MSChannelConfigurationDefault;
  }
}

@end
