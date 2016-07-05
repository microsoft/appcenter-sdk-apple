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

+ (void)setFileManager:(NSFileManager *)fileManager {
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

+ (BOOL)createDirectoryAtPath:(NSString *)directoryPath {
  if (directoryPath) {
    NSError *error = nil;
    if ([self.fileManager createDirectoryAtPath:directoryPath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error]) {
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
    if (![self.fileManager fileExistsAtPath:directoryPath isDirectory:YES]) {
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

- (BOOL)disableBackupForDirectoryURL:(NSURL *)directoryURL {
  NSError *error = nil;
  if (![directoryURL setResourceValue:@YES
                               forKey:NSURLIsExcludedFromBackupKey
                                error:&error]) {
    AVALogError(@"ERROR: Error excluding %@ from backup %@",
                directoryURL.lastPathComponent, error.localizedDescription);
    return NO;
  } else {
    return YES;
  }
}

#pragma mark - File I/O

+ (BOOL)appendData:(NSData *)data toFileWithPath:(NSString *)filePath {
  if (!data || !filePath) {
    return NO;
  }

  BOOL isDir;
  if (![self.fileManager fileExistsAtPath:filePath isDirectory:&isDir] &&
      !isDir) {
    [self createFileAtPath:filePath];
  }

  NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:filePath];
  if (file) {
    [file seekToEndOfFile];
    [file writeData:data];
  }
  return YES;
}

+ (BOOL)deleteFileWithPath:(NSString *)filePath {
  if (!filePath) {
    return NO;
  }

  NSError *error = nil;
  if ([self.fileManager removeItemAtPath:filePath error:&error]) {
    AVALogVerbose(@"VERBOSE: File %@: has been successfully deleted", filePath);
    return YES;
  } else {
    AVALogError(@"ERROR: Error deleting file %@: %@", filePath,
                error.localizedDescription);
    return NO;
  }
}

+ (NSData *)dataForFileWithPath:(NSString *)filePath {
  if (!filePath) {
    return nil;
  }

  NSData *data;
  NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:filePath];
  if (file) {
    data = [file readDataToEndOfFile];
  }
  return data;
}

+ (NSArray *)fileNamesForDirectory:(NSString *)directoryPath
                 withFileExtension:(NSString *)fileExtension {
  if (!directoryPath || !fileExtension) {
    return nil;
  }

  NSError *error;
  NSArray *filteredFiles;
  NSArray *allFiles =
      [self.fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
  if (error) {
    AVALogError(@"ERROR: Couldn't read %@-files for directory %@: %@",
                fileExtension, directoryPath, error.localizedDescription);
  } else {
    NSPredicate *extensionFilter = [NSPredicate
        predicateWithFormat:@"self ENDSWITH[cd]  %@", fileExtension];
    filteredFiles = [allFiles filteredArrayUsingPredicate:extensionFilter];
  }

  return filteredFiles;
}

@end
