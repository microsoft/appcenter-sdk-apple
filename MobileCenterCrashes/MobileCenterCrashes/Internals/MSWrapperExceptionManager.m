#import <CrashReporter/CrashReporter.h>
#import "MSCrashes.h"
#import "MSCrashesInternal.h"
#import "MSException.h"
#import "MSWrapperExceptionManagerInternal.h"
#import "MSWrapperExceptionInternal.h"

@implementation MSWrapperExceptionManager : NSObject

static NSString* const kDirectoryName = @"mc_wrapper_exceptions";
static NSString* const kLastWrapperExceptionFileName = @"last_saved_wrapper_exception";

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

#pragma mark Static methods

+ (instancetype)sharedInstance {
  static MSWrapperExceptionManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (void)deleteAllWrapperExceptions {
  [[self sharedInstance] deleteAllWrapperExceptions];
}

+ (void) correlateLastSavedWrapperExceptionToReport:(NSArray<MSPLCrashReport*> *)reports {
  [[self sharedInstance] correlateLastSavedWrapperExceptionToReport:reports];
}

+ (void) deleteWrapperExceptionWithUUID:(NSString *)uuid {
  [[self sharedInstance] deleteWrapperExceptionWithUUID:uuid];
}

+ (void) deleteWrapperExceptionWithUUIDRef:(CFUUIDRef)uuidRef {
  [[self sharedInstance] deleteWrapperExceptionWithUUIDRef:uuidRef];
}

+ (MSWrapperException *) loadWrapperExceptionWithUUIDRef:(CFUUIDRef)uuidRef {
  return [[self sharedInstance] loadWrapperExceptionWithUUIDRef:uuidRef];
}

+ (void) saveWrapperException:(MSWrapperException *)wrapperException {
  [[self sharedInstance] saveWrapperException:wrapperException];
}

+ (MSWrapperException *) loadWrapperExceptionWithUUID:(NSString *)uuid {
  return [[self sharedInstance] loadWrapperExceptionWithUUID:uuid];
}


#pragma mark Instance methods

- (void) deleteWrapperExceptionWithUUID:(NSString *)uuid
{
  [self deleteWrapperExceptionWithBaseFilename:uuid];
}


- (void) deleteWrapperExceptionWithUUIDRef:(CFUUIDRef)uuidRef
{
  [self deleteWrapperExceptionWithBaseFilename:[[self class] uuidRefToString:uuidRef]];
}

- (void) deleteWrapperExceptionWithBaseFilename:(NSString *)baseFilename
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  for (NSString *filePath in [fileManager enumeratorAtPath:[[self class] directoryPath]]) {
    NSString *actualPath = [[[self class] directoryPath] stringByAppendingPathComponent:filePath];
    NSString *expectedPath = [[self class] getFilename:baseFilename];
    if ([actualPath isEqualToString:expectedPath]) {
      [[self class] deleteFile:actualPath];
      return;
    }
  }
}

- (void)deleteAllWrapperExceptions {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  for (NSString *filePath in [fileManager enumeratorAtPath:[[self class] directoryPath]]) {
      NSString *path = [[[self class] directoryPath] stringByAppendingPathComponent:filePath];
      [[self class] deleteFile:path];
  }
}

- (void) saveWrapperException:(MSWrapperException *)wrapperException {
  [self saveWrapperException:wrapperException withBaseFilename:kLastWrapperExceptionFileName];
}

- (void) saveWrapperException:(MSWrapperException *)wrapperException withBaseFilename:(NSString *)baseFilename {
  NSString *exceptionFilename = [[self class] getFilename:baseFilename];
  BOOL success = [NSKeyedArchiver archiveRootObject:wrapperException toFile:exceptionFilename];
  if (!success) {
    MSLogError([MSCrashes logTag], @"Failed to save wrapper SDK exception file %@", exceptionFilename);
  }
}

- (MSWrapperException *) loadWrapperExceptionWithUUID:(NSString *)uuid {
  return [self loadWrapperExceptionWithBaseFilename:uuid];
}

- (MSWrapperException *) loadWrapperExceptionWithBaseFilename:(NSString *)baseFilename {
  NSString *exceptionFilename = [[self class] getFilename:baseFilename];
  MSWrapperException * wrapperException = [NSKeyedUnarchiver unarchiveObjectWithFile:exceptionFilename];
  return wrapperException;
}

- (MSWrapperException *) loadWrapperExceptionWithUUIDRef:(CFUUIDRef)uuidRef {
  return [self loadWrapperExceptionWithBaseFilename:[[self class] uuidRefToString:uuidRef]];
}

- (void) correlateLastSavedWrapperExceptionToReport:(NSArray<MSPLCrashReport*> *)reports
{
  MSWrapperException *lastSavedWrapperException = [self loadWrapperExceptionWithBaseFilename:kLastWrapperExceptionFileName];

  // Delete the last saved exception from disk if it exists
  if (lastSavedWrapperException) {
    [self deleteWrapperExceptionWithBaseFilename:kLastWrapperExceptionFileName];
  }

  MSPLCrashReport * correspondingReport = nil;
  for (MSPLCrashReport * report in reports) {
    if ([report hasProcessInfo] &&
        [lastSavedWrapperException.processId unsignedIntegerValue] == report.processInfo.processID){
      correspondingReport = report;
      break;
    }
  }
  if (correspondingReport) {
    NSString* uuidString = [[self class] uuidRefToString:correspondingReport.uuidRef];
    [self saveWrapperException:lastSavedWrapperException withBaseFilename:uuidString];
  }
}

#pragma mark Helper methods

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

+ (NSString *)getFilename:(NSString *)filename {
  return [[[self class] directoryPath] stringByAppendingPathComponent:filename];
}

+ (NSString *)uuidRefToString:(CFUUIDRef)uuidRef {
  if (!uuidRef) {
    return nil;
  }
  CFStringRef uuidStringRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
  return (__bridge_transfer NSString *)uuidStringRef;
}

@end
