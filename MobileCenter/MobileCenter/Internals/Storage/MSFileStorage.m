#import "MSFile.h"
#import "MSFileStorage.h"
#import "MSFileUtil.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSUtil.h"

static NSString *const kMSLogsDirectory = @"com.microsoft.azure.mobile.mobilecenter/logs";
static NSString *const kMSFileExtension = @"ms";
// FIXME Need a different storage such as database to make it work properly.
//       For now, persistence will maintain up to 350 logs and remove the oldest 50 logs in a file.
//       Plus, the requirement is to keep 300 logs for all the logs stored accross the bucckets but the limit is
//       currently only applied per bucket.
static NSUInteger const MSDefaultFileCountLimit = 7;
static NSUInteger const MSDefaultLogCountLimit = 50;

@implementation MSFileStorage

@synthesize bucketFileCountLimit = _bucketFileCountLimit;
@synthesize bucketFileLogCountLimit = _bucketFileLogCountLimit;

#pragma mark - Initialisation

- (instancetype)init {
  if ((self = [super init])) {
    _buckets = [NSMutableDictionary<NSString *, MSStorageBucket *> new];
    _bucketFileCountLimit = MSDefaultFileCountLimit;
    _bucketFileLogCountLimit = MSDefaultLogCountLimit;
  }
  return self;
}

#pragma mark - Public

- (BOOL)saveLog:(id<MSLog>)log withGroupID:(NSString *)groupID {
  if (!log) {
    return NO;
  }

  MSStorageBucket *bucket = [self bucketForGroupID:groupID];

  if (bucket.currentLogs.count >= self.bucketFileLogCountLimit) {
    [bucket.currentLogs removeAllObjects];
    [self renewCurrentFileForGroupID:groupID];
  }

  if (bucket.currentLogs.count == 0) {

    // Drop oldest files if needed
    if (bucket.availableFiles.count >= self.bucketFileCountLimit) {
      MSFile *oldestFile = [bucket.availableFiles lastObject];
      [self deleteLogsForId:oldestFile.fileId withGroupID:groupID];
    }

    // Make current file available and create new current file
    [bucket.availableFiles insertObject:bucket.currentFile atIndex:0];
  }

  [bucket.currentLogs addObject:log];
  NSData *logsData = [NSKeyedArchiver archivedDataWithRootObject:bucket.currentLogs];

  return [MSFileUtil writeData:logsData toFile:bucket.currentFile];
}

- (NSArray<MSLog> *)deleteLogsForGroupID:(NSString *)groupID {

  // Cache deleted logs
  NSMutableArray<MSLog> *deletedLogs = [NSMutableArray<MSLog> new];

  // Remove all files from the bucket.
  MSStorageBucket *bucket = self.buckets[groupID];
  NSArray<MSFile *> *allFiles = [bucket removeAllFiles];

  // Delete all files.
  for (MSFile *file in allFiles) {
    [deletedLogs addObjectsFromArray:[self deleteFile:file fromBucket:bucket]];
  }

  // Get ready for next time.
  [self renewCurrentFileForGroupID:groupID];
  return deletedLogs;
}

- (void)deleteLogsForId:(NSString *)logsId withGroupID:(NSString *)groupID {
  MSStorageBucket *bucket = self.buckets[groupID];
  [self deleteFile:[bucket fileWithId:logsId] fromBucket:bucket];
}

- (NSArray<MSLog> *)deleteFile:(MSFile *)file fromBucket:(MSStorageBucket *)bucket {
  NSMutableArray<MSLog> *deletedLogs = [NSMutableArray<MSLog> new];
  if (file) {

    // Cache logs from file.
    NSData *data = [MSFileUtil dataForFile:file];
    if (data) {
      NSArray<MSLog> *logs = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData * _Nonnull)data];
      if (logs) {
        [deletedLogs addObjectsFromArray:logs];
      }
    }

    // Wipe it.
    [MSFileUtil deleteFile:file];
    [bucket removeFile:file];
  }
  return deletedLogs;
}

- (BOOL)loadLogsForGroupID:(NSString *)groupID withCompletion:(nullable MSLoadDataCompletionBlock)completion {
  NSArray<MSLog> *logs;
  NSString *fileId;
  MSStorageBucket *bucket = [self bucketForGroupID:groupID];

  [self renewCurrentFileForGroupID:groupID];

  // Get data of oldest file
  if (bucket.availableFiles.count > 0) {
    MSFile *file = bucket.availableFiles.lastObject;
    fileId = file.fileId;
    NSData *logData = [MSFileUtil dataForFile:file];
    logs = [NSKeyedUnarchiver unarchiveObjectWithData:logData];
    [bucket.blockedFiles addObject:file];
    [bucket.availableFiles removeLastObject];
  }

  // Load fails if no logs found.
  if (completion) {
    completion((logs.count > 0), logs, fileId);
  }

  // Return YES if there are more logs to send.
  return (bucket.availableFiles.count > 0);
}

- (void)closeBatchWithGroupID:(NSString *)groupID {
  [self renewCurrentFileForGroupID:groupID];
}

#pragma mark - Helper

- (MSStorageBucket *)createNewBucketForGroupID:(NSString *)groupID {
  MSStorageBucket *bucket = [MSStorageBucket new];
  NSString *storageDirectory = [self directoryPathForGroupID:groupID];
  NSArray *existingFiles = [MSFileUtil filesForDirectory:storageDirectory withFileExtension:kMSFileExtension];
  if (existingFiles) {
    [bucket.availableFiles addObjectsFromArray:existingFiles];
    [bucket sortAvailableFilesByCreationDate];
  }
  self.buckets[groupID] = bucket;
  [self renewCurrentFileForGroupID:groupID];

  return bucket;
}

- (MSStorageBucket *)bucketForGroupID:(NSString *)groupID {
  MSStorageBucket *bucket = self.buckets[groupID];
  if (!bucket) {
    bucket = [self createNewBucketForGroupID:groupID];
  }

  return bucket;
}

- (void)renewCurrentFileForGroupID:(NSString *)groupID {
  MSStorageBucket *bucket = [self bucketForGroupID:groupID];
  NSDate *creationDate = [NSDate date];
  NSString *fileId = MS_UUID_STRING;
  NSString *filePath = [self filePathForGroupID:groupID logsId:fileId];
  MSFile *file = [[MSFile alloc] initWithPath:filePath fileId:fileId creationDate:creationDate];
  bucket.currentFile = file;
  [bucket.currentLogs removeAllObjects];
}

- (NSString *)directoryPathForGroupID:(NSString *)groupID {
  NSString *filePath = [self.baseDirectoryPath stringByAppendingPathComponent:groupID];

  return filePath;
}

- (NSString *)filePathForGroupID:(NSString *)groupID logsId:(NSString *)logsId {
  NSString *fileName = [logsId stringByAppendingPathExtension:kMSFileExtension];
  NSString *filePath = [[self directoryPathForGroupID:groupID] stringByAppendingPathComponent:fileName];

  return filePath;
}

- (NSString *)baseDirectoryPath {
  if (!_baseDirectoryPath) {
    NSString *appSupportPath =
        [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject]
            stringByStandardizingPath];
    if (appSupportPath) {
      _baseDirectoryPath = [appSupportPath stringByAppendingPathComponent:kMSLogsDirectory];
    }

    MSLogVerbose([MSMobileCenter logTag], @"Storage Path:\n%@", self.baseDirectoryPath);
  }

  return _baseDirectoryPath;
}

@end
