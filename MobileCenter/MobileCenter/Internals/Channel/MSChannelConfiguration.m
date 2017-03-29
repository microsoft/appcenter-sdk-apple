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

// TODO (jaelim): This method will be removed and each service will have its own configuration.
+ (instancetype)configurationForPriority:(MSPriority)priority groupID:(NSString *)groupID {
  switch (priority) {
  case MSPriorityHigh:
    return [[self alloc] initWithGroupID:groupID
                                priority:priority
                           flushInterval:1.0
                          batchSizeLimit:10
                     pendingBatchesLimit:6];
  case MSPriorityBackground:
    return [[self alloc] initWithGroupID:groupID
                                priority:priority
                           flushInterval:60.0
                          batchSizeLimit:100
                     pendingBatchesLimit:1];
  case MSPriorityDefault:
    return [[self alloc] initWithGroupID:groupID
                                priority:priority
                           flushInterval:3.0
                          batchSizeLimit:50
                     pendingBatchesLimit:3];
  }
}

@end
