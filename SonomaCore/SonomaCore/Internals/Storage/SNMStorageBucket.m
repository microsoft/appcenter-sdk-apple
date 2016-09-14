#import "SNMStorageBucket.h"

@implementation SNMStorageBucket

- (instancetype)init {
  if (self = [super init]) {
    _availableFiles = [NSMutableArray new];
    _blockedFiles = [NSMutableArray new];
    _currentLogs = [NSMutableArray<SNMLog> new];
  }
  return self;
}

- (SNMFile *)fileWithId:(NSString *)fileId {
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
      [self.availableFiles sortedArrayUsingComparator:^NSComparisonResult(SNMFile *b1, SNMFile *b2) {
        return [b1.creationDate compare:b2.creationDate];
      }];
  _availableFiles = [sortedBatches mutableCopy];
}

- (void)removeFile:(SNMFile *)file {
  if ([self.availableFiles containsObject:file]) {
    [self.availableFiles removeObject:file];
  }
  if ([self.blockedFiles containsObject:file]) {
    [self.blockedFiles removeObject:file];
  }
}

@end
