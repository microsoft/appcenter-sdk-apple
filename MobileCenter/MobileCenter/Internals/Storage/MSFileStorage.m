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

- (BOOL)saveLog:(id <MSLog>)log withStorageKey:(NSString *)storageKey {
  if (!log) {
    return NO;
  }

  MSStorageBucket *bucket = [self bucketForStorageKey:storageKey];

  if (bucket.currentLogs.count >= self.bucketFileLogCountLimit) {
    [bucket.currentLogs removeAllObjects];
    [self renewCurrentFileForStorageKey:storageKey];
  }

  if (bucket.currentLogs.count == 0) {

    // Drop oldest files if needed
    if (bucket.availableFiles.count >= self.bucketFileCountLimit) {
      MSFile *oldestFile = [bucket.availableFiles lastObject];
      [self deleteLogsForId:oldestFile.fileId withStorageKey:storageKey];
    }

    // Make current file available and create new current file
    [bucket.availableFiles insertObject:bucket.currentFile atIndex:0];
  }

  [bucket.currentLogs addObject:log];
  NSData *logsData = [NSKeyedArchiver archivedDataWithRootObject:bucket.currentLogs];

  return [MSFileUtil writeData:logsData toFile:bucket.currentFile];
}

- (NSArray <MSLog> *)deleteLogsForStorageKey:(NSString *)storageKey {

  // Cache deleted logs
  NSMutableArray <MSLog> *deletedLogs = [NSMutableArray < MSLog > new];

  // Remove all files from the bucket.
  MSStorageBucket *bucket = self.buckets[storageKey];
  NSArray<MSFile *> *allFiles = [bucket removeAllFiles];

  // Delete all files.
  for (MSFile *file in allFiles) {
    [deletedLogs addObjectsFromArray:[self deleteFile:file fromBucket:bucket]];
  }

  // Get ready for next time.
  [self renewCurrentFileForStorageKey:storageKey];
  return deletedLogs;
}

- (void)deleteLogsForId:(NSString *)logsId withStorageKey:(NSString *)storageKey {
  MSStorageBucket *bucket = self.buckets[storageKey];
  [self deleteFile:[bucket fileWithId:logsId] fromBucket:bucket];
}

- (NSArray <MSLog> *)deleteFile:(MSFile *)file fromBucket:(MSStorageBucket *)bucket {
  NSMutableArray <MSLog> *deletedLogs = [NSMutableArray < MSLog > new];
  if (file) {

    // Cache logs from file.
    NSData *data = [MSFileUtil dataForFile:file];
    if (data) {
      NSArray <MSLog> *logs = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData * _Nonnull)data];
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

- (BOOL)loadLogsForStorageKey:(NSString *)storageKey withCompletion:(nullable MSLoadDataCompletionBlock)completion {
  NSArray <MSLog> *logs;
  NSString *fileId;
  MSStorageBucket *bucket = [self bucketForStorageKey:storageKey];

  [self renewCurrentFileForStorageKey:storageKey];

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

- (void)closeBatchWithStorageKey:(NSString *)storageKey {
  [self renewCurrentFileForStorageKey:storageKey];
}

#pragma mark - Helper

- (MSStorageBucket *)createNewBucketForStorageKey:(NSString *)storageKey {
  MSStorageBucket *bucket = [MSStorageBucket new];
  NSURL *storageDirectory = [self directoryURLForStorageKey:storageKey];
  NSArray *existingFiles = [MSFileUtil filesForDirectory:storageDirectory withFileExtension:kMSFileExtension];
  if (existingFiles) {
    [bucket.availableFiles addObjectsFromArray:existingFiles];
    [bucket sortAvailableFilesByCreationDate];
  }
  self.buckets[storageKey] = bucket;
  [self renewCurrentFileForStorageKey:storageKey];

  return bucket;
}

- (MSStorageBucket *)bucketForStorageKey:(NSString *)storageKey {
  MSStorageBucket *bucket = self.buckets[storageKey];
  if (!bucket) {
    bucket = [self createNewBucketForStorageKey:storageKey];
  }

  return bucket;
}

- (void)renewCurrentFileForStorageKey:(NSString *)storageKey {
  MSStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  NSDate *creationDate = [NSDate date];
  NSString *fileId = MS_UUID_STRING;
  NSURL *fileURL = [self fileURLForStorageKey:storageKey logsId:fileId];
  MSFile *file = [[MSFile alloc] initWithURL:fileURL fileId:fileId creationDate:creationDate];
  bucket.currentFile = file;
  [bucket.currentLogs removeAllObjects];
}

- (NSURL *)directoryURLForStorageKey:(NSString *)storageKey {
  NSURL *fileURL = [self.baseDirectoryURL URLByAppendingPathComponent:storageKey];

  return fileURL;
}

- (NSURL *)fileURLForStorageKey:(NSString *)storageKey logsId:(nonnull NSString *)logsId {
  NSString *fileName = [logsId stringByAppendingPathExtension:kMSFileExtension];
  NSURL *fileURL = [[self directoryURLForStorageKey:storageKey] URLByAppendingPathComponent:fileName];

  return fileURL;
}

- (NSURL *)baseDirectoryURL {
  if (!_baseDirectoryURL) {
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    if (appSupportURL) {
      _baseDirectoryURL = (NSURL * _Nonnull)[appSupportURL URLByAppendingPathComponent:kMSLogsDirectory];
    }

    MSLogVerbose([MSMobileCenter logTag], @"Storage Path:\n%@", self->_baseDirectoryURL);
  }

  return _baseDirectoryURL;
}

@end
