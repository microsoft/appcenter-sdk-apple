#import "AVAFileHelper.h"
#import "AVALogger.h"

@interface AVAFileHelper ()

@property(nonatomic, strong) NSFileManager *fileManager;

@end

@implementation AVAFileHelper

#pragma mark - Initialisation

+ (id)sharedInstance {
  static AVAFileHelper *sharedInstance = nil;
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

+ (BOOL)writeData:(NSData *)data toFile:(AVAFile *)file {
  if (!data || !file.filePath) {
    return NO;
  }

  BOOL isDir;
  if (![self.fileManager fileExistsAtPath:file.filePath isDirectory:&isDir]) {
    [self createFileAtPath:file.filePath];
  }

  NSError *error;
  if ([data writeToFile:file.filePath
                options:NSDataWritingAtomic
                  error:&error]) {
    AVALogVerbose(@"VERBOSE: File %@: has been successfully written",
                  file.filePath);
    return YES;
  } else {
    AVALogError(@"ERROR: Error writing file %@: %@", file.filePath,
                error.localizedDescription);
    return NO;
  }
}

+ (BOOL)deleteFile:(AVAFile *)file {
  if (!file.filePath) {
    return NO;
  }

  NSError *error;
  if ([self.fileManager removeItemAtPath:file.filePath error:&error]) {
    AVALogVerbose(@"VERBOSE: File %@: has been successfully deleted",
                  file.filePath);
    return YES;
  } else {
    AVALogError(@"ERROR: Error deleting file %@: %@", file.filePath,
                error.localizedDescription);
    return NO;
  }
}

+ (NSData *)dataForFile:(AVAFile *)file {
  if (!file.filePath) {
    return nil;
  }

  NSError *error;
  NSData *data =
      [NSData dataWithContentsOfFile:file.filePath options:nil error:&error];
  if (error) {
    AVALogError(@"ERROR: Error writing file %@: %@", file.filePath,
                error.localizedDescription);
  } else {
    AVALogVerbose(@"VERBOSE: File %@: has been successfully written",
                  file.filePath);
  }
  return data;
}

+ (NSArray<AVAFile *> *)filesForDirectory:(NSString *)directoryPath
                        withFileExtension:(NSString *)fileExtension {
  if (!directoryPath || !fileExtension) {
    return nil;
  }

  NSMutableArray<AVAFile *> *files;
  NSError *error;
  NSArray *allFiles =
      [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath
                                                          error:&error];
  if (error) {
    AVALogError(@"ERROR: Couldn't read %@-files for directory %@: %@",
                fileExtension, directoryPath, error.localizedDescription);
    return nil;
  } else {
    NSPredicate *extensionFilter = [NSPredicate
        predicateWithFormat:@"self ENDSWITH[cd] %@", fileExtension];
    NSArray *filteredFiles =
        [allFiles filteredArrayUsingPredicate:extensionFilter];

    files = [NSMutableArray new];
    for (NSString *fileName in filteredFiles) {
      NSString *filePath =
          [directoryPath stringByAppendingPathComponent:fileName];
      NSString *fileId = [fileName stringByDeletingPathExtension];
      NSDate *creationDate = [self creationDateForFileAtPath:filePath];
      AVAFile *file = [[AVAFile alloc] initWithPath:filePath
                                             fileId:fileId
                                       creationDate:creationDate];
      [files addObject:file];
    }

    return files;
  }
}

#pragma mark - Helpers

+ (NSDate *)creationDateForFileAtPath:(NSString *)filePath {
  NSError *error;
  NSDate *creationDate;
  NSDictionary *attributes =
      [self.fileManager attributesOfItemAtPath:filePath error:&error];
  if (!error) {
    creationDate = attributes[NSFileCreationDate];
  } else {
    AVALogWarning(@"Warning: Couldn't read creation date of file %@: %@",
                  filePath, error.localizedDescription);
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
      AVALogError(@"ERROR: Couldn't create directory at path %@: %@",
                  directoryPath, error.localizedDescription);
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

    if ([self.fileManager createFileAtPath:filePath
                                  contents:[NSData new]
                                attributes:nil]) {
      return YES;
    } else {
      AVALogError(@"ERROR: Couldn't create new file at path %@", filePath);
    }
  }
  return NO;
}

+ (BOOL)disableBackupForDirectoryPath:(nonnull NSString *)directoryPath {
  NSError *error = nil;
  NSURL *url = [NSURL fileURLWithPath:directoryPath];
  if (!url ||
      ![url setResourceValue:@YES
                      forKey:NSURLIsExcludedFromBackupKey
                       error:&error]) {
    AVALogError(@"ERROR: Error excluding %@ from backup %@", directoryPath,
                error.localizedDescription);
    return NO;
  } else {
    return YES;
  }
}

@end
