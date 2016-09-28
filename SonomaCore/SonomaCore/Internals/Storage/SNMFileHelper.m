#import "SNMFileHelper.h"
#import "SNMLogger.h"

@interface SNMFileHelper ()

@property(nonatomic, strong) NSFileManager *fileManager;

@end

@implementation SNMFileHelper

#pragma mark - Initialisation

+ (instancetype)sharedInstance {
  static SNMFileHelper *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (void)setFileManager:(nullable NSFileManager *)fileManager {
  [self.sharedInstance setFileManager:fileManager];
}

+ (NSFileManager *)fileManager {
  return [self.sharedInstance fileManager];
}

- (NSFileManager *)fileManager {
  if (_fileManager) {
    return _fileManager;
  } else {
    return [NSFileManager defaultManager];
  }
}

#pragma mark - File I/O

+ (BOOL)writeData:(NSData *)data toFile:(SNMFile *)file {
  if (!data || !file.filePath) {
    return NO;
  }

  BOOL isDir;
  if (![self.fileManager fileExistsAtPath:file.filePath isDirectory:&isDir]) {
    [self createFileAtPath:file.filePath];
  }

  NSError *error;
  if ([data writeToFile:file.filePath options:NSDataWritingAtomic error:&error]) {
    SNMLogVerbose(@"VERBOSE: File %@: has been successfully written", file.filePath);
    return YES;
  } else {
    SNMLogError(@"ERROR: Error writing file %@: %@", file.filePath, error.localizedDescription);
    return NO;
  }
}

+ (BOOL)deleteFile:(SNMFile *)file {
  if (!file.filePath) {
    return NO;
  }

  NSError *error;
  if ([self.fileManager removeItemAtPath:file.filePath error:&error]) {
    SNMLogVerbose(@"VERBOSE: File %@: has been successfully deleted", file.filePath);
    return YES;
  } else {
    SNMLogError(@"ERROR: Error deleting file %@: %@", file.filePath, error.localizedDescription);
    return NO;
  }
}

+ (nullable NSData *)dataForFile:(SNMFile *)file {
  if (!file.filePath) {
    return nil;
  }

  NSError *error;
  NSData *data = [NSData dataWithContentsOfFile:file.filePath options:nil error:&error];
  if (error) {
    SNMLogError(@"ERROR: Error writing file %@: %@", file.filePath, error.localizedDescription);
  } else {
    SNMLogVerbose(@"VERBOSE: File %@: has been successfully written", file.filePath);
  }
  return data;
}

+ (NSArray<SNMFile *> *)filesForDirectory:(NSString *)directoryPath withFileExtension:(NSString *)fileExtension {
  NSFileManager *fileManager = [NSFileManager defaultManager];

  // Check validity.
  if (!directoryPath || !fileExtension || ![fileManager fileExistsAtPath:directoryPath]) {
    return nil;
  }

  NSMutableArray<SNMFile *> *files;
  NSError *error;
  NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
  if (error) {
    SNMLogError(@"ERROR: Couldn't read %@-files for directory %@: %@", fileExtension, directoryPath,
                error.localizedDescription);
    return nil;
  } else {
    NSPredicate *extensionFilter = [NSPredicate predicateWithFormat:@"self ENDSWITH[cd] %@", fileExtension];
    NSArray *filteredFiles = [allFiles filteredArrayUsingPredicate:extensionFilter];

    files = [NSMutableArray new];
    for (NSString *fileName in filteredFiles) {
      NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
      NSString *fileId = [fileName stringByDeletingPathExtension];
      NSDate *creationDate = [self creationDateForFileAtPath:filePath];
      SNMFile *file = [[SNMFile alloc] initWithPath:filePath fileId:fileId creationDate:creationDate];
      [files addObject:file];
    }

    return files;
  }
}

#pragma mark - Helpers

+ (NSDate *)creationDateForFileAtPath:(NSString *)filePath {
  NSError *error;
  NSDate *creationDate;
  NSDictionary *attributes = [self.fileManager attributesOfItemAtPath:filePath error:&error];
  if (!error) {
    creationDate = attributes[NSFileCreationDate];
  } else {
    SNMLogWarning(@"Warning: Couldn't read creation date of file %@: %@", filePath, error.localizedDescription);
  }

  return creationDate;
}

+ (BOOL)createDirectoryAtPath:(NSString *)directoryPath {
  if (directoryPath) {
    NSError *error = nil;
    if ([self.fileManager createDirectoryAtPath:directoryPath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error]) {
      [self disableBackupForDirectoryPath:directoryPath];
      return YES;
    } else {
      SNMLogError(@"ERROR: Couldn't create directory at path %@: %@", directoryPath, error.localizedDescription);
    }
  }
  return NO;
}

+ (BOOL)createFileAtPath:(NSString *)filePath {
  if (filePath) {
    NSString *directoryPath = [filePath stringByDeletingLastPathComponent];
    BOOL isDir;
    if (![self.fileManager fileExistsAtPath:directoryPath isDirectory:&isDir]) {
      [self createDirectoryAtPath:directoryPath];
    }

    if ([self.fileManager createFileAtPath:filePath contents:[NSData new] attributes:nil]) {
      return YES;
    } else {
      SNMLogError(@"ERROR: Couldn't create new file at path %@", filePath);
    }
  }
  return NO;
}

+ (BOOL)disableBackupForDirectoryPath:(nonnull NSString *)directoryPath {
  NSError *error = nil;
  NSURL *url = [NSURL fileURLWithPath:directoryPath];
  if (!url || ![url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error]) {
    SNMLogError(@"ERROR: Error excluding %@ from backup %@", directoryPath, error.localizedDescription);
    return NO;
  } else {
    return YES;
  }
}

@end
