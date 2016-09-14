#import "SNMFile.h"
#import "SNMFileHelper.h"
#import "SNMFileStorage.h"
#import "SNMLogger.h"
#import "SNMUtils.h"

static NSString *const kSNMLogsDirectory = @"com.microsoft.sonoma/logs";
static NSString *const kSNMFileExtension = @"snm";
// FIXME Need a different storage such as database to make it work properly.
//       For now, persistence will maintain up to 350 logs and remove the oldest 50 logs in a file.
static NSUInteger const SNMDefaultFileCountLimit = 7;
static NSUInteger const SNMDefaultLogCountLimit = 50;

@implementation SNMFileStorage

@synthesize bucketFileCountLimit = _bucketFileCountLimit;
@synthesize bucketFileLogCountLimit = _bucketFileLogCountLimit;

#pragma mark - Initialisation

- (instancetype)init {
  if (self = [super init]) {
    _buckets = [NSMutableDictionary<NSString *, SNMStorageBucket *> new];
    _bucketFileCountLimit = SNMDefaultFileCountLimit;
    _bucketFileLogCountLimit = SNMDefaultLogCountLimit;
  }
  return self;
}

#pragma mark - Public

- (void)saveLog:(id<SNMLog>)log withStorageKey:(NSString *)storageKey {
  if (!log) {
    return;
  }

  SNMStorageBucket *bucket = [self bucketForStorageKey:storageKey];

  if (bucket.currentLogs.count >= self.bucketFileLogCountLimit) {
    [bucket.currentLogs removeAllObjects];
    [self renewCurrentFileForStorageKey:storageKey];
  }

  if (bucket.currentLogs.count == 0) {

    // Drop oldest files if needed
    if (bucket.availableFiles.count >= self.bucketFileCountLimit) {
      SNMFile *oldestFile = [bucket.availableFiles lastObject];
      [self deleteLogsForId:oldestFile.fileId withStorageKey:storageKey];
    }

    // Make current file available and create new current file
    [bucket.availableFiles insertObject:bucket.currentFile atIndex:0];
  }

  [bucket.currentLogs addObject:log];
  NSData *logsData = [NSKeyedArchiver archivedDataWithRootObject:bucket.currentLogs];
  [SNMFileHelper writeData:logsData toFile:bucket.currentFile];
}

- (void)deleteLogsForId:(NSString *)logsId withStorageKey:(NSString *)storageKey {
  SNMStorageBucket *bucket = self.buckets[storageKey];
  SNMFile *file = [bucket fileWithId:logsId];

  if (file) {
    [SNMFileHelper deleteFile:file];
    [bucket removeFile:file];
  }
}

- (void)loadLogsForStorageKey:(NSString *)storageKey withCompletion:(nullable SNMLoadDataCompletionBlock)completion {
  NSArray<SNMLog> *logs;
  NSString *fileId;
  SNMStorageBucket *bucket = [self bucketForStorageKey:storageKey];

  [self renewCurrentFileForStorageKey:storageKey];

  // Get data of oldest file
  if (bucket.availableFiles.count > 0) {
    SNMFile *file = bucket.availableFiles.lastObject;
    fileId = file.fileId;
    NSData *logData = [SNMFileHelper dataForFile:file];
    logs = [NSKeyedUnarchiver unarchiveObjectWithData:logData];
    [bucket.blockedFiles addObject:file];
    [bucket.availableFiles removeLastObject];
  }

  if (completion) {
    completion(logs, fileId);
  }
}

#pragma mark - Helper

- (SNMStorageBucket *)createNewBucketForStorageKey:(NSString *)storageKey {
  SNMStorageBucket *bucket = [SNMStorageBucket new];
  NSString *storageDirectory = [self directoryPathForStorageKey:storageKey];
  NSArray *existingFiles = [SNMFileHelper filesForDirectory:storageDirectory withFileExtension:kSNMFileExtension];
  if (existingFiles) {
    [bucket.availableFiles addObjectsFromArray:existingFiles];
      [bucket sortAvailableFilesByCreationDate];
  }
  self.buckets[storageKey] = bucket;
  [self renewCurrentFileForStorageKey:storageKey];

  return bucket;
}

- (SNMStorageBucket *)bucketForStorageKey:(NSString *)storageKey {
  SNMStorageBucket *bucket = self.buckets[storageKey];
  if (!bucket) {
    bucket = [self createNewBucketForStorageKey:storageKey];
  }

  return bucket;
}

- (void)renewCurrentFileForStorageKey:(NSString *)storageKey {
  SNMStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  NSDate *creationDate = [NSDate date];
  NSString *fileId = kSNMUUIDString;
  NSString *filePath = [self filePathForStorageKey:storageKey logsId:fileId];
  SNMFile *file = [[SNMFile alloc] initWithPath:filePath fileId:fileId creationDate:creationDate];
  bucket.currentFile = file;
  [bucket.currentLogs removeAllObjects];
}

- (NSString *)directoryPathForStorageKey:(nonnull NSString *)storageKey {
  NSString *filePath = [self.baseDirectoryPath stringByAppendingPathComponent:storageKey];

  return filePath;
}

- (NSString *)filePathForStorageKey:(nonnull NSString *)storageKey logsId:(nonnull NSString *)logsId {
  NSString *fileName = [logsId stringByAppendingPathExtension:kSNMFileExtension];
  NSString *filePath = [[self directoryPathForStorageKey:storageKey] stringByAppendingPathComponent:fileName];

  return filePath;
}

- (NSString *)baseDirectoryPath {
  if (!_baseDirectoryPath) {
    NSString *appSupportPath =
        [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject]
            stringByStandardizingPath];
    if (appSupportPath) {
      _baseDirectoryPath = [appSupportPath stringByAppendingPathComponent:kSNMLogsDirectory];
    }

    SNMLogVerbose(@"Storage Path:\n%@", _baseDirectoryPath);
  }

  return _baseDirectoryPath;
}

@end
