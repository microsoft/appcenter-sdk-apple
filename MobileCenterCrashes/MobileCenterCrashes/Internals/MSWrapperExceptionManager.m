/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSWrapperExceptionManagerInternal.h"
#import "MSCrashes.h"
#import "MSException.h"
#import "MSCrashesInternal.h"
#import "MSStorage.h"

@implementation MSWrapperExceptionManager : NSObject

#pragma mark - Public methods

+ (BOOL)hasException {
  return [[self sharedInstance] hasException];
}

+ (void)setWrapperException:(MSException*)wrapperException {
  [self sharedInstance].wrapperException = wrapperException;
}

+ (void)saveWrapperExceptionData:(CFUUIDRef)uuidRef {
  [[self sharedInstance] saveWrapperExceptionData:uuidRef];
}

+ (NSData*)loadWrapperExceptionDataWithUUIDString:(NSString*)uuidString {
  return [[self sharedInstance] loadWrapperExceptionDataWithUUIDString:uuidString];
}

+ (MSException*)loadWrapperException:(CFUUIDRef)uuidRef {
  return [[self sharedInstance] loadWrapperException:uuidRef];
}

+ (void)saveWrapperException:(CFUUIDRef)uuidRef {
  [[self sharedInstance] saveWrapperException:uuidRef];
}

+ (void)setWrapperExceptionData:(NSData *)data {
  [self sharedInstance].unsavedWrapperExceptionData = data;
}

+ (void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef {
  [[self sharedInstance] deleteWrapperExceptionWithUUID:uuidRef];
}

+ (void)deleteAllWrapperExceptions {
  [[self sharedInstance] deleteAllWrapperExceptions];
}

+ (void)deleteWrapperExceptionDataWithUUIDString:(NSString*)uuidString {
  [[self sharedInstance] deleteWrapperExceptionDataWithUUIDString:uuidString];
}
+ (void)deleteAllWrapperExceptionData {
  [[self sharedInstance] deleteAllWrapperExceptionData];
}

+ (void)setDelegate:(id<MSWrapperCrashesInitializationDelegate>) delegate {
  [self sharedInstance].crashesDelegate = delegate;
}

+ (id<MSWrapperCrashesInitializationDelegate>)getDelegate {
  return [self sharedInstance].crashesDelegate;
}

+ (void) startCrashReportingFromWrapperSdk {
  [[self sharedInstance] startCrashReportingFromWrapperSdk];
}

#pragma mark - Private methods

- (instancetype)init {
  if ((self = [super init])) {

    _unsavedWrapperExceptionData = nil;
    _wrapperException = nil;
    _wrapperExceptionData = [[NSMutableDictionary alloc] init];
    _currentUUIDRef = nil;

    // Create the directory if it doesn't exist
    NSFileManager *defaultManager = [NSFileManager defaultManager];

    if (![defaultManager fileExistsAtPath:[[self class] directoryPath]]) {
      NSError *error = nil;
      [defaultManager createDirectoryAtPath:[[self class] directoryPath]
                withIntermediateDirectories:NO
                                 attributes:nil
                                      error:&error];
      if (error) {
        MSLogError([MSCrashes logTag], @"Failed to create directory %@: %@",
                   [[self class] directoryPath], error.localizedDescription);
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

- (BOOL)hasException {
  return _wrapperException != nil;
}

- (MSException*)loadWrapperException:(CFUUIDRef)uuidRef {
  if (_wrapperException && [[self class] isCurrentUUIDRef:uuidRef]) {
    return _wrapperException;
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

  _wrapperException = loadedException;
  _currentUUIDRef = uuidRef;

  return _wrapperException;
}

- (void)saveWrapperException:(CFUUIDRef)uuidRef {
  NSString *filename = [[self class] getFilenameWithUUIDRef:uuidRef];
  [self saveWrapperExceptionData:uuidRef];
  BOOL success = [NSKeyedArchiver archiveRootObject:_wrapperException toFile:filename];
  if (!success) {
    MSLogError([MSCrashes logTag], @"Failed to save file %@", filename);
  }
}

- (void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef {
  NSString *path = [MSWrapperExceptionManager getFilenameWithUUIDRef:uuidRef];
  [[self class] deleteFile:path];

  if ([[self class] isCurrentUUIDRef:uuidRef]) {
    _currentUUIDRef = nil;
    _wrapperException = nil;
  }
}

- (void)deleteAllWrapperExceptions {
  _currentUUIDRef = nil;
  _wrapperException = nil;

  NSFileManager *fileManager = [NSFileManager defaultManager];

  for (NSString *filePath in [fileManager enumeratorAtPath:[[self class] directoryPath]]) {
    if (![[self class] isDataFile:filePath]) {
      NSString *path = [[[self class] directoryPath] stringByAppendingPathComponent:filePath];
      [[self class] deleteFile:path];
    }
  }
}

- (void)saveWrapperExceptionData:(CFUUIDRef)uuidRef {
  if (!_unsavedWrapperExceptionData) {
    return;
  }
  NSString* dataFilename = [[self class] getDataFilenameWithUUIDRef:uuidRef];
  [_unsavedWrapperExceptionData writeToFile:dataFilename atomically:YES];
}

- (NSData*)loadWrapperExceptionDataWithUUIDString:(NSString*)uuidString {
  NSString *dataFilename = [[self class] getDataFilename:uuidString];
  NSData *data = [_wrapperExceptionData objectForKey:dataFilename];
  if (data) {
    return data;
  }
  NSError *error = nil;
  data = [NSData dataWithContentsOfFile:dataFilename options:NSDataReadingMappedIfSafe error:&error];
  if (error) {
    MSLogError([MSCrashes logTag], @"Error loading file %@: %@",
               dataFilename, error.localizedDescription);
  }
  return data;
}

- (void)deleteWrapperExceptionDataWithUUIDString:(NSString*)uuidString {
  NSString* dataFilename = [[self class] getDataFilename:uuidString];
  NSData *data = [self loadWrapperExceptionDataWithUUIDString:uuidString];
  if (data) {
    [_wrapperExceptionData setObject:data forKey:dataFilename];
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

+ (void)deleteFile:(NSString*)path {
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    return;
  }
  NSError *error = nil;
  [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
  if (error) {
    MSLogError([MSCrashes logTag], @"Error deleting file %@: %@",
               path, error.localizedDescription);
  }
}

+ (NSString*)uuidRefToString:(CFUUIDRef)uuidRef {
  if (!uuidRef) {
    return nil;
  }
  CFStringRef uuidStringRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
  return (__bridge_transfer NSString*)uuidStringRef;
}

+ (BOOL)isCurrentUUIDRef:(CFUUIDRef)uuidRef {
  CFUUIDRef currentUUIDRef = [self sharedInstance].currentUUIDRef;

  BOOL currentUUIDRefIsNull = (currentUUIDRef == nil);
  BOOL uuidRefIsNull = (uuidRef == nil);

  if (currentUUIDRefIsNull && uuidRefIsNull) {
    return true;
  }
  if (currentUUIDRefIsNull || uuidRefIsNull) {
    return false;
  }

  // For whatever reason, CFEqual causes a crash, so we compare strings
  NSString *uuidString = [self uuidRefToString:uuidRef];
  NSString *currentUUIDString = [self uuidRefToString:currentUUIDRef];

  return [uuidString isEqualToString:currentUUIDString];
}

- (void) startCrashReportingFromWrapperSdk {
  [[MSCrashes sharedInstance] configureCrashReporter];
}

+ (NSString*)dataFileExtension {
  return @"ms";
}

+ (NSString*)directoryName {
  return @"wrapper_exceptions";
}

+ (NSString*)directoryPath {

  static NSString* path = nil;

  if (!path) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    path = [documentsDirectory stringByAppendingPathComponent:[self directoryName]];
  }

  return path;
}

+ (NSString*)getFilename:(NSString*)uuidString {
  return [[self directoryPath] stringByAppendingPathComponent:uuidString];
}

+ (NSString*)getDataFilename:(NSString*)uuidString {
  NSString *filename = [MSWrapperExceptionManager getFilename:uuidString];
  return [filename stringByAppendingPathExtension:[self dataFileExtension]];
}

+ (NSString*)getFilenameWithUUIDRef:(CFUUIDRef)uuidRef {
  NSString *uuidString = [MSWrapperExceptionManager uuidRefToString:uuidRef];
  return [MSWrapperExceptionManager getFilename:uuidString];
}

+ (NSString*)getDataFilenameWithUUIDRef:(CFUUIDRef)uuidRef {
  NSString *uuidString = [MSWrapperExceptionManager uuidRefToString:uuidRef];
  return [MSWrapperExceptionManager getDataFilename:uuidString];
}

+ (BOOL) isDataFile:(NSString*)path {
  return [path hasSuffix:[@"." stringByAppendingString:[self dataFileExtension]]];
}

@end
