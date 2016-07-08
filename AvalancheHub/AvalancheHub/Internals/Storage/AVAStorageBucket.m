#import "AVAStorageBucket.h"

@implementation AVAStorageBucket

- (instancetype)init {
  if (self = [super init]) {
    _availableFiles = [NSMutableArray new];
    _blockedFiles = [NSMutableArray new];
  }
  return self;
}

- (AVAFile *)fileWithId:(NSString *)fileId {
  NSString *propertyName = @"fileId";
  NSPredicate *predicte = [NSPredicate predicateWithFormat:
                           @"%K = %@",propertyName, fileId];
  
  NSArray *results = [self.blockedFiles filteredArrayUsingPredicate:predicte];
  if(!results || !results.lastObject) {
    results = [self.availableFiles filteredArrayUsingPredicate:predicte];
  }
  
  return results.lastObject;
}

- (void)sortAvailableFilesByCreationDate {
  NSArray *sortedBatches = [self.availableFiles sortedArrayUsingComparator: ^NSComparisonResult(AVAFile *b1, AVAFile *b2) {
    return [b1.creationDate compare:b2.creationDate];
  }];
  _availableFiles = [sortedBatches mutableCopy];
}

@end
