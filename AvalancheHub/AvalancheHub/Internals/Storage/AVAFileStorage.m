#import "AVAFileHelper.h"
#import "AVALogger.h"
#import "AVAFileStorage.h"
#import "AVAFile.h"
#import "AVAEventLog.h"

static NSString *const kAVALogsDirectory = @"com.microsoft.avalanche/logs";
static NSString *const kAVAFileExtension = @"ava";
static NSUInteger const AVADefaultBucketFileCountLimit = 50;

@implementation AVAFileStorage

@synthesize bucketFileCountLimit = _bucketFileCountLimit;

#pragma mark - Initialisation

- (instancetype)init {
  if (self = [super init]) {
    _buckets = [NSMutableDictionary<NSString *, AVAStorageBucket *> new];
    _bucketFileCountLimit = AVADefaultBucketFileCountLimit;
  }
  return self;
}

#pragma mark - Public

- (void)saveLog:(id<AVALog>)log withStorageKey:(NSString *)storageKey {
  NSMutableDictionary *logDict = [NSMutableDictionary new];
  [log write:logDict];
  NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:logDict];
  AVAStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  [AVAFileHelper appendData:logData toFile:bucket.currentFile];
}

- (void)deleteLogsForId:(NSString *)logsId
         withStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = self.buckets[storageKey];
  AVAFile *file = [bucket fileWithId:logsId];
  
  if(file) {
    [AVAFileHelper deleteFile:file];
    [bucket.blockedFiles removeObject:file];
  }
}

- (void)loadLogsForStorageKey:(NSString *)storageKey
               withCompletion:(nullable loadDataCompletionBlock)completion {
  // Read data from current file
  AVAStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  AVAFile *file = bucket.currentFile;
  NSData *logData = [AVAFileHelper dataForFile:file];
  NSDictionary *logDict = [NSKeyedUnarchiver unarchiveObjectWithData:logData];
  AVAEventLog *log = [AVAEventLog new];
  [log read:logDict];
  NSArray<AVALog> *logArray = [NSArray<AVALog> arrayWithObject:log];
  
  // Change status of the file to `blocked`
  [bucket.blockedFiles addObject:file];
  
  // Renew file for upcoming events
  [self renewCurrentFileForStorageKey:storageKey];
  
  if(completion) {
    completion(logArray, file.fileId);
  }
}

- (BOOL)maxFileCountReachedForStorageKey:(NSString *) storageKey {
  AVAStorageBucket *bucket = self.buckets[storageKey];
  NSUInteger filesCount = bucket.availableFiles.count + bucket.blockedFiles.count;
  return (filesCount >= self.bucketFileCountLimit);
}

#pragma mark - Helper

- (AVAStorageBucket *)createNewBucketForStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = [AVAStorageBucket new];
  NSString *storageDirectory = [self directoryPathForStorageKey:storageKey];
  NSArray *existingFiles = [AVAFileHelper filesForDirectory:storageDirectory withFileExtension:kAVAFileExtension];
  if(existingFiles) {
    [bucket.availableFiles addObjectsFromArray:existingFiles];
    [bucket sortAvailableFilesByCreationDate];
  }
  self.buckets[storageKey] = bucket;
  [self renewCurrentFileForStorageKey:storageKey];
  
  return bucket;
}

- (AVAStorageBucket *)bucketForStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = self.buckets[storageKey];
  if (!bucket) {
    bucket = [self createNewBucketForStorageKey:storageKey];
  }

  return bucket;
}

- (void)renewCurrentFileForStorageKey:(NSString *)storageKey {
  AVAStorageBucket *bucket = [self bucketForStorageKey:storageKey];
  NSDate *creationDate = [NSDate date];
  NSString *fileId = [[NSUUID UUID] UUIDString];
  NSString *filePath = [self filePathForStorageKey:storageKey logsId:fileId];
  AVAFile *file = [[AVAFile alloc] initWithPath:filePath fileId:fileId creationDate:creationDate];
  bucket.currentFile = file;
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
