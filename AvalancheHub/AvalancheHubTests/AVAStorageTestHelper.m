#import "AVAStorageTestHelper.h"

@implementation AVAStorageTestHelper

+ (NSString *)logsDir {
  NSString *logsPath = @"com.microsoft.avalanche/logs";
  NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
  return [documentsDir stringByAppendingPathComponent:logsPath];
}

+ (NSString *)storageDirForStorageKey:(NSString *)storageKey {
  return [[self logsDir] stringByAppendingPathComponent:storageKey];
}

+ (void)createLogFileWithId:(NSString *)logsId data:(NSData *)data extension:(NSString *)extension storageKey:(NSString *)storageKey {
  NSString *storagePath = [self storageDirForStorageKey:storageKey];
  if(![[NSFileManager defaultManager] fileExistsAtPath:storagePath]) {
    [self createDirectoryAtPath:storagePath];
  }
  
  NSString *filePath = [self filePathForLogWithId:logsId extension:extension storageKey:storageKey];
  [[NSFileManager defaultManager] createFileAtPath:filePath contents:data attributes:nil];
}

+ (void)createDirectoryAtPath:(NSString *)directoryPath {
  NSError *error;
  [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:&error];
}

+ (NSString *)filePathForLogWithId:(NSString *)logsId extension:(NSString *)extension storageKey:(NSString *)storageKey {
  NSString *fileName = [logsId stringByAppendingPathExtension:extension];
  NSString *logFilePath = [storageKey stringByAppendingPathComponent:fileName];
  NSString *logsPath = [self logsDir];
  
  return [logsPath stringByAppendingPathComponent:logFilePath];
}

+ (void)resetLogsDirectory {
  [[NSFileManager defaultManager] removeItemAtPath:[self logsDir] error:nil];
}

@end
