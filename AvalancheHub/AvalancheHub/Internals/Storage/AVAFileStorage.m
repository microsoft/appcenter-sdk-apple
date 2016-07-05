#import "AVAFileHelper.h"
#import "AVALogger.h"
#import "AVAFileStorage.h"

static NSString *const kAVALogsDirectory = @"com.microsoft.avalanche/logs";
static NSString *const kAVAFileExtension = @"ava";

@implementation AVAFileStorage

@synthesize fileCountLimit;

#pragma mark - Initialisation

- (instancetype)init {
  if (self = [super init]) {
    _buckets = [NSMutableDictionary<NSString *, AVAStorageBucket *> new];
  }
  return self;
}

#pragma mark - Public

- (void)saveLog:(id<AVALog>)log withStorageKey:(NSString *)storageKey {
  // TODO: Serialize item
  NSData *logData = [NSData new];
  NSString *filePath = [self currentFilePathForStorageKey:storageKey];
  [AVAFileHelper appendData:logData toFileWithPath:filePath];
}

- (void)deleteLogsForId:(NSString *)logsId
         withStorageKey:(NSString *)storageKey {
  NSString *filePath = [self filePathForStorageKey:storageKey logsId:logsId];

  // Remove file from in memory list
  [AVAFileHelper deleteFileWithPath:filePath];

  // Delete file from disk
  AVAStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  [bucket.blockedFiles removeObject:logsId];
}

- (void)loadLogsForStorageKey:(NSString *)storageKey
               withCompletion:(nullable loadDataCompletionBlock)completion {
  // Read data from current file
  NSString *filePath = [self currentFilePathForStorageKey:storageKey];
  NSData *logsData = [AVAFileHelper dataForFileWithPath:filePath];

  // Renew file for upcoming events
  NSString *logsId = [self renewFilePathForStorageKey:storageKey];

  // Return data and batch id
  // TODO: Deserialize data
  completion(nil, logsId);
}

#pragma mark - Helper

- (NSString *)currentFilePathForStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  NSString *filePath = bucket.currentFilePath;

  return filePath;
}

- (AVAStorageBucket *)createNewBucketForStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = [AVAStorageBucket new];
  self.buckets[storageKey] = bucket;
  [self renewFilePathForStorageKey:storageKey];
  
  return bucket;
}

- (AVAStorageBucket *)bucketForStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = self.buckets[storageKey];
  if (!bucket) {
    bucket = [self createNewBucketForStorageKey:storageKey];
  }

  return bucket;
}

- (NSString *)renewFilePathForStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  NSString *logsId = [[NSUUID UUID] UUIDString];
  NSString *filePath = [self filePathForStorageKey:storageKey logsId:logsId];
  bucket.currentFilePath = filePath;

  return logsId;
}

- (NSString *)filePathForStorageKey:(nonnull NSString *)storageKey
                             logsId:(nonnull NSString *)logsId {
  NSString *fileName = [logsId stringByAppendingPathExtension:kAVAFileExtension];
  NSString *filePath =
      [[self.baseDirectoryPath stringByAppendingPathComponent:storageKey] stringByAppendingPathComponent:fileName];
  
  return filePath;
}

- (NSString *)baseDirectoryPath {
  if (!_baseDirectoryPath) {
    NSString *appSupportPath = [[NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject]
        stringByStandardizingPath];
    if (appSupportPath) {
      _baseDirectoryPath =
          [appSupportPath stringByAppendingPathComponent:kAVALogsDirectory];
    }
  }

  return _baseDirectoryPath;
}

@end
