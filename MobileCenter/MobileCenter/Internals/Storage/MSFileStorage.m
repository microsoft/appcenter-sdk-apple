#import "MSFile.h"
#import "MSFileStorage.h"
#import "MSFileUtil.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"

static NSString *const kMSLogsDirectory = @"com.microsoft.azure.mobile.mobilecenter/logs";
static NSString *const kMSFileExtension = @"ms";
// FIXME Need a different storage such as database to make it work properly.
//       For now, persistence will maintain up to 350 logs and remove the oldest 50 logs in a file.
//       Plus, the requirement is to keep 300 logs for all the logs stored across the buckets but the limit is
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

- (BOOL)saveLog:(id<MSLog>)log withGroupId:(NSString *)groupId {
  if (!log) {
    return NO;
  }

  MSStorageBucket *bucket = [self bucketForGroupId:groupId];

  if (bucket.currentLogs.count >= self.bucketFileLogCountLimit) {
    [bucket.currentLogs removeAllObjects];
    [self renewCurrentFileForGroupId:groupId];
  }

  if (bucket.currentLogs.count == 0) {

    // Drop oldest files if needed
    if (bucket.availableFiles.count >= self.bucketFileCountLimit) {
      MSFile *oldestFile = [bucket.availableFiles lastObject];
      [self deleteLogsForId:oldestFile.fileId withGroupId:groupId];
    }

    // Make current file available and create new current file
    [bucket.availableFiles insertObject:bucket.currentFile atIndex:0];
  }

  [bucket.currentLogs addObject:log];
  NSData *logsData = [NSKeyedArchiver archivedDataWithRootObject:bucket.currentLogs];

  return [MSFileUtil writeData:logsData toFile:bucket.currentFile];
}

- (NSArray<MSLog> *)deleteLogsForGroupId:(NSString *)groupId {

  // Cache deleted logs
  NSMutableArray<MSLog> *deletedLogs = [NSMutableArray<MSLog> new];

  // Remove all files from the bucket.
  MSStorageBucket *bucket = self.buckets[groupId];
  NSArray<MSFile *> *allFiles = [bucket removeAllFiles];

  // Delete all files.
  for (MSFile *file in allFiles) {
    [deletedLogs addObjectsFromArray:[self deleteFile:file fromBucket:bucket]];
  }

  // Get ready for next time.
  [self renewCurrentFileForGroupId:groupId];
  return deletedLogs;
}

- (void)deleteLogsForId:(NSString *)logsId withGroupId:(NSString *)groupId {
  MSStorageBucket *bucket = self.buckets[groupId];
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

- (BOOL)loadLogsForGroupId:(NSString *)groupId withCompletion:(nullable MSLoadDataCompletionBlock)completion {
  NSArray<MSLog> *logs;
  NSString *fileId;
  MSStorageBucket *bucket = [self bucketForGroupId:groupId];

  [self renewCurrentFileForGroupId:groupId];

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

- (void)closeBatchWithGroupId:(NSString *)groupId {
  [self renewCurrentFileForGroupId:groupId];
}

#pragma mark - Helper

- (MSStorageBucket *)createNewBucketForGroupId:(NSString *)groupId {
  MSStorageBucket *bucket = [MSStorageBucket new];
  NSURL *storageDirectory = [self directoryURLForGroupId:groupId];
  NSArray *existingFiles = [MSFileUtil filesForDirectory:storageDirectory withFileExtension:kMSFileExtension];
  if (existingFiles) {
    [bucket.availableFiles addObjectsFromArray:existingFiles];
    [bucket sortAvailableFilesByCreationDate];
  }
  self.buckets[groupId] = bucket;
  [self renewCurrentFileForGroupId:groupId];

  return bucket;
}

- (MSStorageBucket *)bucketForGroupId:(NSString *)groupId {
  MSStorageBucket *bucket = self.buckets[groupId];
  if (!bucket) {
    bucket = [self createNewBucketForGroupId:groupId];
  }

  return bucket;
}

- (void)renewCurrentFileForGroupId:(NSString *)groupId {
  MSStorageBucket *bucket = [self bucketForGroupId:groupId];
  NSDate *creationDate = [NSDate date];
  NSString *fileId = MS_UUID_STRING;
  NSURL *fileURL = [self fileURLForGroupId:groupId logsId:fileId];
  MSFile *file = [[MSFile alloc] initWithURL:fileURL fileId:fileId creationDate:creationDate];
  bucket.currentFile = file;
  [bucket.currentLogs removeAllObjects];
}

- (NSURL *)directoryURLForGroupId:(NSString *)groupId {
  NSURL *fileURL = [self.baseDirectoryURL URLByAppendingPathComponent:groupId];

  return fileURL;
}

- (NSURL *)fileURLForGroupId:(NSString *)groupId logsId:(nonnull NSString *)logsId {
  NSString *fileName = [logsId stringByAppendingPathExtension:kMSFileExtension];
  NSURL *fileURL = [[self directoryURLForGroupId:groupId] URLByAppendingPathComponent:fileName];

  return fileURL;
}

- (NSURL *)baseDirectoryURL {
  if (!_baseDirectoryURL) {
#if TARGET_OS_TV
    // TODO: This is a temporary change. Make sure this implementation is correct.
    _baseDirectoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:kMSLogsDirectory]];
#else
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    if (appSupportURL) {
      _baseDirectoryURL = (NSURL * _Nonnull)[appSupportURL URLByAppendingPathComponent:kMSLogsDirectory];
    }
#endif
    NSURL *url = _baseDirectoryURL;
    MSLogVerbose([MSMobileCenter logTag], @"Storage Path:\n%@", url);
  }

  return _baseDirectoryURL;
}

@end
