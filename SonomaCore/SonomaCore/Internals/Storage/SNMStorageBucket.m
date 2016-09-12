#import "SNMStorageBucket.h"

@implementation SNMStorageBucket

- (instancetype)init {
  if (self = [super init]) {
    _SNMilableFiles = [NSMutableArray new];
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
    results = [self.SNMilableFiles filteredArrayUsingPredicate:predicte];
  }

  return results.lastObject;
}

- (void)sortSNMilableFilesByCreationDate {
  NSArray *sortedBatches =
      [self.SNMilableFiles sortedArrayUsingComparator:^NSComparisonResult(SNMFile *b1, SNMFile *b2) {
        return [b1.creationDate compare:b2.creationDate];
      }];
  _SNMilableFiles = [sortedBatches mutableCopy];
}

- (void)removeFile:(SNMFile *)file {
  if ([self.SNMilableFiles containsObject:file]) {
    [self.SNMilableFiles removeObject:file];
  }
  if ([self.blockedFiles containsObject:file]) {
    [self.blockedFiles removeObject:file];
  }
}

@end
