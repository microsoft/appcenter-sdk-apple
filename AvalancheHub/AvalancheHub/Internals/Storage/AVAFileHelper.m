#import "AVAFileHelper.h"

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

- (NSFileManager *)fileManager {
  if (_fileManager) {
    return _fileManager;
  } else {
    return [NSFileManager defaultManager];
  }
}

#pragma mark - File I/O

+ (BOOL)appendData:(NSData *)data toFileWithPath:(NSString *)filePath {
  return YES;
}

+ (BOOL)deleteFileWithPath:(NSString *)filePath {

  return YES;
}

+ (NSData *)dataForFileWithPath:(NSString *)filePath {
  return nil;
}

+ (NSArray *)fileNamesForDirectory:(NSString *)directoryPath
                 withFileExtension:(NSString *)fileExtension {
  return nil;
}

@end
