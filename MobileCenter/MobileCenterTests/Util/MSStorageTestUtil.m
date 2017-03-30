#import "MSStorageTestUtil.h"

@implementation MSStorageTestUtil

+ (NSString *)logsDir {
  NSString *logsPath = @"com.microsoft.azure.mobile.mobilecenter/logs";
  NSString *documentsDir =
      [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
  return [documentsDir stringByAppendingPathComponent:logsPath];
}

+ (NSString *)storageDirForGroupID:(NSString *)groupID {
  return [[self logsDir] stringByAppendingPathComponent:groupID];
}

+ (NSString *)filePathForLogWithId:(NSString *)logsId extension:(NSString *)extension groupID:(NSString *)groupID {
  NSString *fileName = [logsId stringByAppendingPathExtension:extension];
  NSString *logFilePath = [groupID stringByAppendingPathComponent:fileName];
  NSString *logsPath = [self logsDir];

  return [logsPath stringByAppendingPathComponent:logFilePath];
}

+ (MSFile *)createFileWithId:(NSString *)logsId
                        data:(NSData *)data
                   extension:(NSString *)extension
                     groupID:(NSString *)groupID
                creationDate:(NSDate *)creationDate {
  NSString *storagePath = [self storageDirForGroupID:groupID];
  if (![[NSFileManager defaultManager] fileExistsAtPath:storagePath]) {
    [self createDirectoryAtPath:storagePath];
  }

  NSString *filePath = [self filePathForLogWithId:logsId extension:extension groupID:groupID];
  [[NSFileManager defaultManager] createFileAtPath:filePath contents:data attributes:nil];

  NSURL *fileURL = [NSURL fileURLWithPath:filePath];
  MSFile *file = [[MSFile alloc] initWithURL:fileURL fileId:logsId creationDate:creationDate];

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
