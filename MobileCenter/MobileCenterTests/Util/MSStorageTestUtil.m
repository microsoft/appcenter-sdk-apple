#import "MSStorageTestUtil.h"

@implementation MSStorageTestUtil

+ (NSString *)logsDir {
  NSString *logsPath = @"com.microsoft.azure.mobile.mobilecenter/logs";
  NSString *documentsDir =
      [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
  return [documentsDir stringByAppendingPathComponent:logsPath];
}

+ (NSString *)storageDirForStorageKey:(NSString *)storageKey {
  return [[self logsDir] stringByAppendingPathComponent:storageKey];
}

+ (NSString *)filePathForLogWithId:(NSString *)logsId
                         extension:(NSString *)extension
                        storageKey:(NSString *)storageKey {
  NSString *fileName = [logsId stringByAppendingPathExtension:extension];
  NSString *logFilePath = [storageKey stringByAppendingPathComponent:fileName];
  NSString *logsPath = [self logsDir];

  return [logsPath stringByAppendingPathComponent:logFilePath];
}

+ (MSFile *)createFileWithId:(NSString *)logsId
                        data:(NSData *)data
                   extension:(NSString *)extension
                  storageKey:(NSString *)storageKey
                creationDate:(NSDate *)creationDate {
  NSString *storagePath = [self storageDirForStorageKey:storageKey];
  if (![[NSFileManager defaultManager] fileExistsAtPath:storagePath]) {
    [self createDirectoryAtPath:storagePath];
  }

  NSString *filePath = [self filePathForLogWithId:logsId extension:extension storageKey:storageKey];
  [[NSFileManager defaultManager] createFileAtPath:filePath contents:data attributes:nil];

  MSFile *file = [[MSFile alloc] initWithPath:filePath fileId:logsId creationDate:creationDate];

  return file;
}

+ (void)createDirectoryAtPath:(NSString *)directoryPath {
  NSError *error;
  [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:&error];
}

+ (void)resetLogsDirectory {
  [[NSFileManager defaultManager] removeItemAtPath:[self logsDir] error:nil];
}

@end

d
