#import "MSCrashes.h"
#import "MSCrashesInternal.h"
#import "MSException.h"
#import "MSWrapperExceptionManagerInternal.h"

@implementation MSWrapperExceptionManager : NSObject

const NSString* kDirectoryName = @"wrapper_exceptions";
const NSString* kDataFileExtension = @"ms";
const NSString* kCorrelationFileName = @"wrapper_exception_correlation_data";

- (instancetype)init {
  if ((self = [super init])) {

    // Create the directory if it doesn't exist
    NSFileManager *defaultManager = [NSFileManager defaultManager];

    if (![defaultManager fileExistsAtPath:[[self class] directoryPath]]) {
      NSError *error = nil;
      [defaultManager createDirectoryAtPath:[[self class] directoryPath]
                withIntermediateDirectories:NO
                                 attributes:nil
                                      error:&error];
      if (error) {
        MSLogError([MSCrashes logTag], @"Failed to create directory %@: %@", [[self class] directoryPath],
                   error.localizedDescription);
      }
    }
  }

  return self;
}

+ (instancetype)sharedInstance {
  static MSWrapperExceptionManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (MSException *)loadWrapperException:(CFUUIDRef)uuidRef {
  if (self.wrapperException && [[self class] isCurrentUUIDRef:uuidRef]) {
    return self.wrapperException;
  }
  NSString *filename = [[self class] getFilenameWithUUIDRef:uuidRef];
  if (![[NSFileManager defaultManager] fileExistsAtPath:filename]) {
    return nil;
  }
  MSException *loadedException = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];

  if (!loadedException) {
    MSLogError([MSCrashes logTag], @"Could not load wrapper exception from file %@", filename);
    return nil;
  }

  self.wrapperException = loadedException;
  self.currentUUIDRef = uuidRef;

  return self.wrapperException;
}

- (void)saveWrapperException:(CFUUIDRef)uuidRef {
  NSString *filename = [[self class] getFilenameWithUUIDRef:uuidRef];
  [self saveWrapperExceptionData:uuidRef];
  BOOL success = [NSKeyedArchiver archiveRootObject:self.wrapperException toFile:filename];
  if (!success) {
    MSLogError([MSCrashes logTag], @"Failed to save file %@", filename);
  }
}

- (void)saveWrapperExceptionData:(NSData *)exceptionData WithUUIDString:(NSString *)uuidString {
  [exceptionData writeToFile:[[self class] getDataFilename:uuidString] atomically:YES];
}

- (void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef {
  NSString *path = [MSWrapperExceptionManager getFilenameWithUUIDRef:uuidRef];
  [[self class] deleteFile:path];

  if ([[self class] isCurrentUUIDRef:uuidRef]) {
    self.currentUUIDRef = nil;
    self.wrapperException = nil;
  }
}

- (void)deleteAllWrapperExceptions {
  self.currentUUIDRef = nil;
  self.wrapperException = nil;

  NSFileManager *fileManager = [NSFileManager defaultManager];

  for (NSString *filePath in [fileManager enumeratorAtPath:[[self class] directoryPath]]) {
    if (![[self class] isDataFile:filePath]) {
      NSString *path = [[[self class] directoryPath] stringByAppendingPathComponent:filePath];
      [[self class] deleteFile:path];
    }
  }
}

- (void) saveWrapperException:(MSWrapperException *)wrapperException {
  NSUUID * wrapperUuid = [NSUUID uuid];
  // Save data
  NSString *dataFilename = [[self class] getDataFilenameWithUUIDRef:wrapperUuid];
  [self.unsavedWrapperExceptionData writeToFile:dataFilename atomically:YES];
}


- (NSData *)loadWrapperExceptionDataWithUUIDString:(NSString *)uuidString {
  NSString *dataFilename = [[self class] getDataFilename:uuidString];
  NSData *data = self.wrapperExceptionData[dataFilename];
  if (data) {
    return data;
  }
  NSError *error = nil;
  data = [NSData dataWithContentsOfFile:dataFilename options:NSDataReadingMappedIfSafe error:&error];
  if (error) {
    MSLogError([MSCrashes logTag], @"Error loading file %@: %@", dataFilename, error.localizedDescription);
  }
  return data;
}

- (void)deleteWrapperExceptionDataWithUUIDString:(NSString *)uuidString {
  NSString *dataFilename = [[self class] getDataFilename:uuidString];
  NSData *data = [self loadWrapperExceptionDataWithUUIDString:uuidString];
  if (data) {
    self.wrapperExceptionData[dataFilename] = data;
  }
  [[self class] deleteFile:dataFilename];
}

- (void)deleteAllWrapperExceptionData {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  for (NSString *filePath in [fileManager enumeratorAtPath:[[self class] directoryPath]]) {
    if ([[self class] isDataFile:filePath]) {
      NSString *path = [[[self class] directoryPath] stringByAppendingPathComponent:filePath];
      [[self class] deleteFile:path];
    }
  }
}

+ (MSException*)exceptionWithType:(NSString*)type message:(NSString*)message stackTrace:(NSString*)stackTrace wrapperSdkName:(NSString*)wrapperSdkName {
  MSException *exception = [[MSException alloc] init];
  exception.type = type;
  exception.message = message;
  exception.stackTrace = stackTrace;
  exception.wrapperSdkName = wrapperSdkName;
  return exception;
}

- (void)trackWrapperException:(MSException*)exception withData:(NSData*)data fatal:(BOOL)fatal {
  NSString* errorId = [[MSCrashes sharedInstance] trackWrapperException:exception fatal:fatal];
  [self saveWrapperExceptionData:data WithUUIDString:errorId];
}

+ (void)deleteFile:(NSString *)path {
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    return;
  }
  NSError *error = nil;
  [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
  if (error) {
    MSLogError([MSCrashes logTag], @"Error deleting file %@: %@", path, error.localizedDescription);
  }
}

+ (NSString *)directoryPath {
  static NSString *path = nil;
  if (!path) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    path = [documentsDirectory stringByAppendingPathComponent:kDirectoryName];
  }
  return path;
}

+ (NSString *)getFilename:(NSString *)uuidString {
  return [[[self class] directoryPath] stringByAppendingPathComponent:uuidString];
}

+ (NSString *)getDataFilename:(NSString *)uuidString {
  NSString *filename = [[self class] getFilename:uuidString];
  return [filename stringByAppendingPathExtension:[self dataFileExtension]];
}

+ (BOOL)isDataFile:(NSString *)path {
  return [path hasSuffix:[@"." stringByAppendingString:[self dataFileExtension]]];
}

@end
