#import "MSStorageBucket.h"

@implementation MSStorageBucket

- (instancetype)init {
  if (self = [super init]) {
    _availableFiles = [NSMutableArray new];
    _blockedFiles = [NSMutableArray new];
    _currentLogs = [NSMutableArray<MSLog> new];
  }
  return self;
}

- (MSFile *)fileWithId:(NSString *)fileId {
  NSString *propertyName = @"fileId";
  NSPredicate *predicte = [NSPredicate predicateWithFormat:@"%K = %@", propertyName, fileId];

  NSArray *results = [self.blockedFiles filteredArrayUsingPredicate:predicte];
  if (!results || !results.lastObject) {
    results = [self.availableFiles filteredArrayUsingPredicate:predicte];
  }

  return results.lastObject;
}

- (void)sortAvailableFilesByCreationDate {
  NSArray *sortedBatches =
      [self.availableFiles sortedArrayUsingComparator:^NSComparisonResult(MSFile *b1, MSFile *b2) {
        return [b1.creationDate compare:b2.creationDate];
      }];
  _availableFiles = [sortedBatches mutableCopy];
}

- (void)removeFile:(MSFile *)file {
  if ([self.availableFiles containsObject:file]) {
    [self.availableFiles removeObject:file];
  }
  if ([self.blockedFiles containsObject:file]) {
    [self.blockedFiles removeObject:file];
  }
}

- (NSArray<MSFile *> *)removeAllFiles {
  NSMutableArray *allFiles = [NSMutableArray new];

  // Transfer all available files
  [allFiles addObjectsFromArray:_availableFiles];
  [_availableFiles removeAllObjects];

  // Transfer all blocked files
  [allFiles addObjectsFromArray:_blockedFiles];
  [_blockedFiles removeAllObjects];
  return [allFiles copy];
}

@end
