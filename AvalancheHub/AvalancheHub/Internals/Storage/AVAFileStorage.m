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
  AVAStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  NSString *filePath = bucket.currentFilePath;
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
  AVAStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  NSString *filePath = bucket.currentFilePath;
  NSData *logsData = [AVAFileHelper dataForFileWithPath:filePath];
  
  // Change status of the file to `blocked`
  [bucket.blockedFiles addObject:bucket.currentLogsId];
  NSString *logsId = bucket.currentLogsId;
  
  // Renew file for upcoming events
  [self renewFilePathForStorageKey:storageKey];
  
  // Return data and batch id
  // TODO: Deserialize data
  if(completion) {
    completion(nil, logsId);
  }
}

#pragma mark - Helper

- (AVAStorageBucket *)createNewBucketForStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = [AVAStorageBucket new];
  NSString *storageDirectory = [self directoryPathForStorageKey:storageKey];
  NSArray *existingFileNames = [AVAFileHelper fileNamesForDirectory:storageDirectory withFileExtension:kAVAFileExtension];
  if(existingFileNames) {
    [bucket.availableFiles addObjectsFromArray:existingFileNames];
  }
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

- (void)renewFilePathForStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  NSString *logsId = [[NSUUID UUID] UUIDString];
  NSString *filePath = [self filePathForStorageKey:storageKey logsId:logsId];
  bucket.currentFilePath = filePath;
  bucket.currentLogsId = logsId;
}

- (NSString *)directoryPathForStorageKey:(nonnull NSString *)storageKey {
  NSString *filePath =
  [self.baseDirectoryPath stringByAppendingPathComponent:storageKey];
  
  return filePath;
}

- (NSString *)filePathForStorageKey:(nonnull NSString *)storageKey
                             logsId:(nonnull NSString *)logsId {
  NSString *fileName = [logsId stringByAppendingPathExtension:kAVAFileExtension];
  NSString *filePath =
      [[self directoryPathForStorageKey:storageKey] stringByAppendingPathComponent:fileName];
  
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
