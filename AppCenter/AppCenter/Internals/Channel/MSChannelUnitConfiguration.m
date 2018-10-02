#import "MSChannelUnitConfiguration.h"

@implementation MSChannelUnitConfiguration

- (instancetype)initWithGroupId:(NSString *)groupId
                       priority:(MSPriority)priority
                  flushInterval:(float)flushInterval
                 batchSizeLimit:(NSUInteger)batchSizeLimit
            pendingBatchesLimit:(NSUInteger)pendingBatchesLimit {
  if ((self = [super init])) {
    _groupId = groupId;
    _priority = priority;
    _flushInterval = flushInterval;
    _batchSizeLimit = batchSizeLimit;
    _pendingBatchesLimit = pendingBatchesLimit;
  }
  return self;
}

- (instancetype)initDefaultConfigurationWithGroupId:(NSString *)groupId {
  return [self initWithGroupId:groupId priority:MSPriorityDefault flushInterval:3.0 batchSizeLimit:50 pendingBatchesLimit:3];
}

@end
