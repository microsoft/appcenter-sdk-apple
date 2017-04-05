#import "MSChannelConfiguration.h"

@implementation MSChannelConfiguration

- (instancetype)initWithGroupID:(NSString *)groupID
                       priority:(MSPriority)priority
                  flushInterval:(float)flushInterval
                 batchSizeLimit:(NSUInteger)batchSizeLimit
            pendingBatchesLimit:(NSUInteger)pendingBatchesLimit {
  if ((self = [super init])) {
    _groupID = groupID;
    _priority = priority;
    _flushInterval = flushInterval;
    _batchSizeLimit = batchSizeLimit;
    _pendingBatchesLimit = pendingBatchesLimit;
  }
  return self;
}

- (instancetype)initDefaultConfigurationWithGroupID:(NSString *)groupID {
  return [self initWithGroupID:groupID
                      priority:MSPriorityDefault
                 flushInterval:3.0
                batchSizeLimit:50
           pendingBatchesLimit:3];
}

@end
