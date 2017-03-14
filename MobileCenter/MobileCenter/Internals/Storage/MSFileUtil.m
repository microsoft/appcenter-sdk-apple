#import "MSFileUtil.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"

/**
 * Private declarations.
 */
@interface MSFileUtil ()

@property(nonatomic) NSFileManager *fileManager;

@end

@implementation MSFileUtil

#pragma mark - Initialisation

+ (instancetype)sharedInstance {
  static MSFileUtil *sharedInstance = nil;
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

+ (BOOL)writeData:(NSData *)data toFile:(MSFile *)file {
  if (!data || !file.fileURL) {
    return NO;
  }

  [self createFileAtURL:file.fileURL];

  NSError *error;
  if ([data writeToURL:file.fileURL options:NSDataWritingAtomic error:&error]) {
    MSLogVerbose([MSMobileCenter logTag], @"File %@: has been successfully written", file.fileURL);
    return YES;
  } else {
    MSLogError([MSMobileCenter logTag], @"Error writing file %@: %@", file.fileURL, error.localizedDescription);
    return NO;
  }
}

+ (BOOL)deleteFile:(MSFile *)file {
  if (!file.fileURL) {
    return NO;
  }

  NSError *error;
  if ([self.fileManager removeItemAtURL:file.fileURL error:&error]) {
    MSLogVerbose([MSMobileCenter logTag], @"File %@: has been successfully deleted", file.fileURL);
    return YES;
  } else {
    MSLogError([MSMobileCenter logTag], @"Error deleting file %@: %@", file.fileURL, error.localizedDescription);
    return NO;
  }
}

+ (nullable NSData *)dataForFile:(MSFile *)file {
  if (!file.fileURL) {
    return nil;
  }

  NSError *error;
  NSData *data = [NSData dataWithContentsOfURL:file.fileURL options:nil error:&error];
  if (error) {
    MSLogError([MSMobileCenter logTag], @"Error writing file %@: %@", file.fileURL, error.localizedDescription);
  } else {
    MSLogVerbose([MSMobileCenter logTag], @"File %@: has been successfully written", file.fileURL);
  }
  return data;
}

+ (nullable NSArray<MSFile *> *)filesForDirectory:(nullable NSURL *)directoryURL
                                withFileExtension:(nullable NSString *)fileExtension {
  NSFileManager *fileManager = [NSFileManager defaultManager];

  // Check validity.
  if (!directoryURL || !fileExtension) {
    return nil;
  }
  NSString * path = [directoryURL path];

  // Check file existing
  if (!path || ![fileManager fileExistsAtPath:path]) {
    return nil;
  }

  NSMutableArray<MSFile *> *files;
  NSError *error;
  NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:path error:&error];
  if (error) {
    MSLogError([MSMobileCenter logTag], @"Couldn't read %@-files for directory %@: %@", fileExtension, path,
                error.localizedDescription);
    return nil;
  } else {
    NSPredicate *extensionFilter = [NSPredicate predicateWithFormat:@"self ENDSWITH[cd] %@", fileExtension];
    NSArray *filteredFiles = [allFiles filteredArrayUsingPredicate:extensionFilter];

    files = [NSMutableArray new];
    for (NSString *fileName in filteredFiles) {
      NSURL *fileURL = [directoryURL URLByAppendingPathComponent:fileName];
      NSString *fileId = [fileName stringByDeletingPathExtension];
      NSDate *creationDate = [self creationDateForFileAtURL:fileURL];
      MSFile *file = [[MSFile alloc] initWithURL:fileURL fileId:fileId creationDate:creationDate];
      [files addObject:file];
    }

    return files;
  }
}

#pragma mark - Helpers

+ (NSDate *)creationDateForFileAtURL:(NSURL *)fileURL {
  NSError *error;
  NSDate *creationDate;
  [fileURL getResourceValue:&creationDate forKey:NSURLContentModificationDateKey error:&error];
  if (error) {
    MSLogWarning([MSMobileCenter logTag], @"Couldn't read creation date of file %@: %@", fileURL, error.localizedDescription);
  }

  return creationDate;
}

+ (BOOL)createDirectoryAtURL:(NSURL *)directoryURL {
  if (directoryURL) {
    NSError *error = nil;
    if ([self.fileManager createDirectoryAtURL:directoryURL
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error]) {
      [self disableBackupForDirectoryURL:directoryURL];
      return YES;
    } else {
      MSLogError([MSMobileCenter logTag], @"Couldn't create directory at path %@: %@", directoryURL, error.localizedDescription);
    }
  }
  return NO;
}

+ (BOOL)createFileAtURL:(NSURL *)fileURL {
  if (fileURL) {
    NSString * filePath = [fileURL path];
    if (!filePath || [self.fileManager fileExistsAtPath:filePath]) {
        return NO;
    }
    NSURL * directoryURL = [fileURL URLByDeletingLastPathComponent];
    NSString * directoryPath = [directoryURL path];
    if (directoryPath && ![self.fileManager fileExistsAtPath:directoryPath]) {
      [self createDirectoryAtURL:directoryURL];
    }

    if ([self.fileManager createFileAtPath:filePath contents:[NSData new] attributes:nil]) {
      return YES;
    } else {
      MSLogError([MSMobileCenter logTag], @"Couldn't create new file at path %@", filePath);
    }
  }
  return NO;
}

+ (BOOL)disableBackupForDirectoryURL:(nonnull NSURL *)directoryURL {
  NSError *error = nil;
  if (!directoryURL || ![directoryURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error]) {
    MSLogError([MSMobileCenter logTag], @"Error excluding %@ from backup %@", directoryURL, error.localizedDescription);
    return NO;
  } else {
    return YES;
  }
}

@end
