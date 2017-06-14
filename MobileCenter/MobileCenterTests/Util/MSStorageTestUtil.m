#import "MSStorageTestUtil.h"
#import "MSUtility.h"

@implementation MSStorageTestUtil

+ (NSString *)logsDir {
  NSString *logsPath = @"com.microsoft.azure.mobile.mobilecenter/logs";
#if TARGET_OS_OSX
  logsPath = [NSString stringWithFormat:@"%@/%@", [MS_APP_MAIN_BUNDLE bundleIdentifier], logsPath];
#endif
  NSString *documentsDir =
      [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
  return [documentsDir stringByAppendingPathComponent:logsPath];
}

+ (NSString *)storageDirForGroupId:(NSString *)groupId {
  return [[self logsDir] stringByAppendingPathComponent:groupId];
}

+ (NSString *)filePathForLogWithId:(NSString *)logsId extension:(NSString *)extension groupId:(NSString *)groupId {
  NSString *fileName = [logsId stringByAppendingPathExtension:extension];
  NSString *logFilePath = [groupId stringByAppendingPathComponent:fileName];
  NSString *logsPath = [self logsDir];

  return [logsPath stringByAppendingPathComponent:logFilePath];
}

+ (MSFile *)createFileWithId:(NSString *)logsId
                        data:(NSData *)data
                   extension:(NSString *)extension
                     groupId:(NSString *)groupId
                creationDate:(NSDate *)creationDate {
  NSString *storagePath = [self storageDirForGroupId:groupId];
  if (![[NSFileManager defaultManager] fileExistsAtPath:storagePath]) {
    [self createDirectoryAtPath:storagePath];
  }

  NSString *filePath = [self filePathForLogWithId:logsId extension:extension groupId:groupId];
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
