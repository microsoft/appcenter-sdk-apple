#import "AVAFileHelper.h"
#import "AVALogger.h"
#import "AVAFileStorage.h"

static NSString *const kAVALogsDirectory = @"com.microsoft.avalanche/logs";
static NSString *const kAVAFileExtension = @".ava";

@implementation AVAFileStorage

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
               withCompletion:(void (^)(NSArray<NSObject<AVALog> *> *,
                                        NSString *))completion {
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

- (AVAStorageBucket *)bucketForStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = self.buckets[storageKey];
  if (!bucket) {
    self.buckets[storageKey] = [AVAStorageBucket new];
  }

  return bucket;
}

- (NSString *)renewFilePathForStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  NSString *logsId = [NSUUID UUID];
  NSString *filePath = [self filePathForStorageKey:storageKey logsId:logsId];
  bucket.currentFilePath = filePath;

  return logsId;
}

- (NSString *)filePathForStorageKey:(NSString *)storageKey
                             logsId:(NSString *)logsId {
  NSString *fileName =
      [logsId stringByAppendingPathComponent:kAVAFileExtension];
  NSString *filePath =
      [self.baseDirectoryPath stringByAppendingString:fileName];
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
