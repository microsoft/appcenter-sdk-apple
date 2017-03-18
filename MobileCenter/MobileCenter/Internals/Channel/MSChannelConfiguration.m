#import "MSChannelConfiguration.h"

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
    return [[self alloc] initWithGroupID:groupID flushInterval:1.0 batchSizeLimit:10 pendingBatchesLimit:6];
  case MSPriorityBackground:
    return [[self alloc] initWithGroupID:groupID flushInterval:60.0 batchSizeLimit:100 pendingBatchesLimit:1];
    case MSPriorityDefault:
      return [[self alloc] initWithGroupID:groupID flushInterval:3.0 batchSizeLimit:50 pendingBatchesLimit:3];
  default:
    return [[self alloc] initWithGroupID:groupID flushInterval:3.0 batchSizeLimit:50 pendingBatchesLimit:3];
  }
}

@end
